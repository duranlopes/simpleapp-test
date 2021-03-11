
import requests
import asyncio

url = "http://app.prova"

async def main():
    while True:
        response = requests.request("GET", url)
        print(response.text)


loop = asyncio.get_event_loop()  
loop.run_until_complete(main())  

