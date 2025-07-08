
import os
import base64
from openai import AzureOpenAI

endpoint = os.getenv("ENDPOINT_URL", "https://nevil-mctuioss-eastus2.openai.azure.com/")
deployment = os.getenv("DEPLOYMENT_NAME", "gpt-4.1")
subscription_key = os.getenv("AZURE_OPENAI_API_KEY", "EzBHgcxCWWIdYZb90MF6funaU7P1SOBy6YCidKz35MmKhytHaT0kJQQJ99BGACHYHv6XJ3w3AAAAACOG4H6y")

# Initialize Azure OpenAI client with key-based authentication
client = AzureOpenAI(
    azure_endpoint=endpoint,
    api_key=subscription_key,
    api_version="2025-01-01-preview",
)

# IMAGE_PATH = "YOUR_IMAGE_PATH"
# encoded_image = base64.b64encode(open(IMAGE_PATH, 'rb').read()).decode('ascii')

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
        'content': '''Please analyze this extracted OCR text electricity bill text and extract the key information:\n\n ['台7鼋力公司', '107年0 7月缴费瘛趱(金融椴耩代缴用户 )', 'WWWtaipowercom.tw', 'Jul. 2018 Payment Receipt', 'Fi 历', '唐 ?1| CO ', '567', '莨:节', '449', '&1鬟 .x礞,然', '"10', '上扌2乏9令」-入?N2 =7', '长31.5252', '先生/女士/贫跷', '虿浆羡禺 :V0107072338854', '鱼噩 (Customer_Number', '盥旦趄 (Pyment_Dte)', '愿盥骢金」 (Tobl', 'Arount)', '107/07/23', '头***2617 元', 't宦期罔', '107.04.27至107.06.27', '下次扣5日', '107.09.23', '恰谥荏 蛮缸趾 :互', '戗缘代`:耶互', '#尤`料', '豇Q凶_爸', '州 改瘘 ', '表垤', '非惹某用', '2706.6元', 'JA00-00081004', '皴密', '鬟鼋费', '32.8元', '箭窀L劭', '-122.4元', '怠度', 'f粲赘(度)', 'Energy Consmmption (h)', '虺盥盟金甑', '2617元', '皮教', '1071', '公共用窀分c卢赵', '10', '已由代壤囊『"汨扌毖', 'g习$去i[」思屯灾』227足 :', '53169', '比汶项目', '用屯9A', '友赵', '日平与芨彀', '诚少用^虽', '~', '1071', '17.27', '204', '去年回期', '1192', '20.55', '1070723', '去年-期', '1398', '23.30', '女华-', '客阢干+(Custoner Seiice)', '1911', '本公司贬}', '68887960', '蹩桊魏-倦禽贾X燮u', '胝秽界位 :台市匠茗粜旋', '末|恣蹬吝项黛颉莪亨`由樵蛋印出 `如蛋巩非癔&列印', '服秽地址', '700台南市忠嶷路一段109筑', '戎方沦改字#戎『忾皮孚匦茗', '-E急女', '用鼋地址', '鎏鳄M118;跷;', '6-1', '632240(27/621+2', '39420427483143.52*340 (27/62)+4.80871 (27/62)+1.6322', '+2.892340135/62)+3.9487135752)', '苤d:', '002091871', ')击倍憝 :', '0001', '本迩/正次抄丧日', '107.0.28/107', '08.29', '苤别咀芒进西', '太别', '01', '上酆指敖^', '57423', '本期|f', '58494']'''
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
    