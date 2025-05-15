import asyncio
import aiohttp
import time
from collections import defaultdict
import sys

MAX_ITERATIONS = 5

url = "http://localhost:8080/"

api_keys = [
    "api_key_1",
    "api_key_2",
    "api_key_3"
]

response_counts = defaultdict(lambda: {"200_OK": 0, "429_TOO_MANY_REQUESTS": 0})

async def send_requests(session, api_key, req_sec):
    for i in range(0,MAX_ITERATIONS):
        tasks = []
        for _ in range(req_sec):
            tasks.append(send_request(session, api_key))
        await asyncio.gather(*tasks)
        await asyncio.sleep(1)

async def send_request(session, api_key):
    headers = {"Authorization": api_key}
    current_time = time.time()  
    current_time_str = time.strftime("%H:%M:%S", time.localtime(current_time)) 

    async with session.get(url, headers=headers) as response:
        if response.status == 200:
            response_counts[api_key]["200_OK"] += 1
        elif response.status == 429:
            response_counts[api_key]["429_TOO_MANY_REQUESTS"] += 1

        print(f"Request time: {current_time_str} Response for {api_key[-5:]}: {response.status}")

def print_statistics(req_sec: int):
    print("\nStatistics:")
    for api_key, counts in response_counts.items():
        print(f"API Key: {api_key[-5:]} {req_sec}/s -> Success rate: {counts['200_OK']/MAX_ITERATIONS} req/s, error rate {counts['429_TOO_MANY_REQUESTS']/MAX_ITERATIONS} req/s")



async def main(req_sec: int):
    async with aiohttp.ClientSession() as session:
        tasks = []
        for api_key in api_keys:
            tasks.append(send_requests(session, api_key, req_sec))
        
        await asyncio.gather(*tasks)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        req_sec = int(sys.argv[1])
    else:
        req_sec = 5
    asyncio.run(main(req_sec))
    print("\nExiting... Printing statistics")
    print_statistics(req_sec)
