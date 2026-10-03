# tei_rerank_adapter.py
import http.server
import urllib.request
import json
import time
import sys
import os # 引入系统库

class Color:
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    ENDC = '\033[0m'

# 动态读取环境变量，若未提供，则默认回退到你当前的本地网络地址
TEI_ENDPOINT = os.environ.get('TEI_ENDPOINT', 'http://tei-rerank:80/rerank')

def log_info(msg):
    print(f"{Color.CYAN}[TEI-Adapter]{Color.ENDC} {msg}", flush=True)

def log_success(msg):
    print(f"{Color.GREEN}[SUCCESS]{Color.ENDC} {msg}", flush=True)

def log_error(msg):
    print(f"{Color.WARNING}[ERROR]{Color.ENDC} {msg}", flush=True, file=sys.stderr)

class RerankTranslatorProxy(http.server.BaseHTTPRequestHandler):
    
    def log_message(self, format, *args):
        pass

    def do_POST(self):
        start_time = time.time()
        try:
            content_length = int(self.headers['Content-Length'])
            body = json.loads(self.rfile.read(content_length))
            
            query = body.get('query', '')
            documents = body.get('documents') or body.get('texts') or []
            
            log_info(f"收到重排请求 | Query: {Color.PURPLE}'{query}'{Color.ENDC} | 候选文档数: {len(documents)}")

            # 1. 协议翻译：AstrBot -> TEI
            tei_payload = {
                'query': query,
                'texts': documents
            }
            
            # 使用动态注入的 TEI_ENDPOINT 转发
            req = urllib.request.Request(
                TEI_ENDPOINT,
                data=json.dumps(tei_payload).encode('utf-8'),
                headers={'Content-Type': 'application/json'}
            )
            
            with urllib.request.urlopen(req) as response:
                tei_res = json.loads(response.read().decode('utf-8'))
                
                # 2. 协议翻译：TEI -> AstrBot results 格式 [1.1.3, 1.2.4]
                results = []
                for item in tei_res:
                    results.append({
                        'index': item.get('index', 0),
                        'relevance_score': item.get('score') or item.get('relevance_score') or 0.0
                    })
                
                vllm_response = {'results': results}
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(vllm_response).encode('utf-8'))
                
                latency = (time.time() - start_time) * 1000
                log_success(f"重排完成 | 耗时: {latency:.2f}ms | 最佳匹配 Index: {results[0]['index'] if results else 'None'}")
                
        except Exception as e:
            latency = (time.time() - start_time) * 1000
            log_error(f"处理失败 | 耗时: {latency:.2f}ms | 原因: {str(e)}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode('utf-8'))

if __name__ == '__main__':
    port = 80
    log_info(f"配置的目标 Reranker 地址: {Color.PURPLE}{TEI_ENDPOINT}{Color.ENDC}")
    log_info(f"极速重排适配器启动，正在监听 0.0.0.0:{port} ...")
    server = http.server.HTTPServer(('0.0.0.0', port), RerankTranslatorProxy)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass