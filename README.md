# Implementing API Key Rate Limiting with nginx
This is a simple example that demonstrates how to enable API key rate limiting using OpenResty in combination with the [lua-resty-limit-traffic](https://github.com/openresty/lua-resty-limit-traffic) library.  
The provided solution helps manage traffic by enforcing limits on the number of API requests based on an API key, protecting your application from abuse and ensuring fair use of resources.  
The current implementation uses a JSON file as the data source for API keys and rate plan configurations. However, the solution is flexible and can be adapted to use other data sources, such as PostgreSQL, Redis, or any other suitable database, depending on your system’s needs and scalability requirements 

## Setup Instructions
### API KEY Configuration
Begin by configuring your API keys and their respective rate limits in the rate-limit.json file. This file contains a mapping between each API key and its rate limit (requests per second). For example:
```json
{
    "DEFAULT": 1,
    "api_key_1": 5,
    "api_key_2": 5,
    "api_key_3": 10
}
```
**DEFAULT**: The default rate limit for any API key not explicitly listed.
**api_key_1, api_key_2, api_key_3**: Specific rate limits for each API key.  
**Important Note**: Currently, the default code supports only the rate limits of 1, 5, and 10 requests per second. To add additional rate limits, you would need to modify the code itself to support new values or dynamic configuration.

### Docker Compose Setup 
To run the example with OpenResty, use Docker Compose to quickly set up the required services. Simply execute the following command:
```bash
docker-compose up
```
This will start the necessary containers, including Nginx OpenResty, which will handle API rate limiting based on the configuration in rate-limit.json.

### Test the Rate Limits
After the services are up and running, you can test the rate limits by running the Python script test_rate_limit.py.   
Update the api_keys list on this script to use your configured api_keys:
```python
api_keys = [
    "api_key_1",  
    "api_key_2",
    "api_key_3",
]
```
Previously dependencies must be installed.
```
pip install -r requirements.txt
```
This script accepts the number of requests per second (req/s) to be tested as a command-line argument. For example:

```bash
python test_rate_limit.py 3
```
This will send the specified number of requests per second and will help you verify that the rate limiting is functioning as expected for each API key.

