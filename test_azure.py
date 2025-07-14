
import os
import base64
from openai import AzureOpenAI
from pdf2image import convert_from_path

endpoint = os.getenv("ENDPOINT_URL", "https://nevil-mctuioss-eastus2.openai.azure.com/")
deployment = os.getenv("DEPLOYMENT_NAME", "gpt-4.1")
subscription_key = os.getenv("AZURE_OPENAI_API_KEY", "EzBHgcxCWWIdYZb90MF6funaU7P1SOBy6YCidKz35MmKhytHaT0kJQQJ99BGACHYHv6XJ3w3AAAAACOG4H6y")

# Initialize Azure OpenAI client with key-based authentication
client = AzureOpenAI(
    azure_endpoint=endpoint,
    api_key=subscription_key,
    api_version="2025-01-01-preview",
)

images = convert_from_path("billl.pdf", dpi=200, poppler_path= r"poppler-24.08.0\Library\bin")
image_path = "bill_page1.jpg"
images[0].save(image_path, "JPEG")
IMAGE_PATH = "billl.pdf"
encoded_image = base64.b64encode(open(image_path, 'rb').read()).decode('ascii')

#Prepare the chat prompt
chat_prompt = [
    {
        "role": "system",
        "content": [
            {
                
                "type": "text",
                "text": '''You are an expert in analyzing electricity bills. Extract key information and provide insights in the following JSON format:
{
  "summary": "Brief summary of the bill",
  "billDate": "YYYY-MM-DD",
  "totalAmount": 0.0,
  "consumptionKwh": 0.0,
  "ratePerKwh": 0.0,
  "insights": ["Array of insights about the bill"],
  "recommendations": ["Array of energy-saving recommendations"]
}'''
            }
        ]
    },
    {
        'role': 'user',
        'content': [
            {
                "type": "image_url",
                "image_url": {
                    "url": f"data:image/jpeg;base64,{encoded_image}"
                }
            },
            {
                "type": "text",
                "text": "Create a summary of this electricity bill"
            }
        ]
    }
]

# Include speech result if speech is enabled
messages = chat_prompt

# Generate the completion
completion = client.chat.completions.create(
    model=deployment,
    messages=messages,
    max_tokens=800,
    temperature=1,
    top_p=1,
    frequency_penalty=0,
    presence_penalty=0,
    stop=None,
    stream=False
)

print(completion.choices[0].message.content)
    