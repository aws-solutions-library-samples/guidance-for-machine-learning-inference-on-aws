import requests
import json


url="http://localhost:8000/v2/models/bert-base-multilingual-cased-1/infer"
headers = {'Content-Type': 'application/json'}
data = {"inputs":[{"name":"seq_0","shape":[1,1],"datatype":"BYTES","data":["What does the little engine say"]},{"name":"seq_1","shape":[1,1],"datatype":"BYTES","data":["In the childrens story about the little engine a small locomotive is pulling a large load up a mountain. Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: \"I think I can\" as it is pulling the heavy load all the way to the top of the mountain. On the way down it says: \"I thought I could\"."]}]}

session = requests.Session()

#result = session.get(url)

#result = session.post(url,headers,data)

strJson = json.dumps(data)
print(strJson)

result = session.post(url=url, data=strJson)

print(result)
print(result.content)

