import { ChatCompletion,Choice, ChatCompletionChunk,
  ChatCompletionSystemMessageParam,
  ChatCompletionUserMessageParam,
  ChatCompletionAssistantMessageParam,
  ChatCompletionFunctionMessageParam,
  IChatCompletionMessageParam, OpenAI,
  ChatCompletionToolMessageParam,
  ChatCompletionMessageToolCall} from '@adrian_wang/openai'
import ChatItem from '../../viewmodel/ChatItem';
import AccountData from '../../viewmodel/AccountData';
import { Tool } from './Tool';


import { AiDialogData } from '../../view/AiDialogComponent';
import { IChatCompletionPostData } from '@adrian_wang/openai/src/main/ets/AsyncCall';
import { ChatCompletionToolParam } from '@adrian_wang/openai/src/main/ets/Function';
import { ChatCompletionMessage } from '@adrian_wang/openai/src/main/ets/ChatCompletion';
import { emitter } from '@kit.BasicServicesKit';

@Observed
class Openai {


  private openaiClient: OpenAI
  public  messageList: IChatCompletionMessageParam[];

  constructor() {
    this.openaiClient = new OpenAI(
      // "sk-sX5SuWY74QzIusIjfKaefj416JVXYRwCX9LGfSCsVx069AUv",
      // "sk-y390j1shuvAdFLxikmGcncnPju28383TD7xN6bEreTfxtMkC",
      "sk-8285fe317edc44ef95f029be9b7cfe94",
      undefined,
      // "https://api.chatanywhere.tech/v1",
      // "https://chatapi.littlewheat.com/v1",
      "https://dashscope.aliyuncs.com/compatible-mode/v1",
    )
    this.messageList = []
  }

  // 添加系统消息
  addSystemMessage(content:string) {
    this.messageList.push(new ChatCompletionSystemMessageParam(content))
  }

  // 添加用户消息
  addUserMessage(content:string) {
    this.messageList.push(new ChatCompletionUserMessageParam(content))
  }

  // 添加机器人消息
  addAssistantMessage(content:string) {
    this.messageList.push(new ChatCompletionAssistantMessageParam(content))
  }

  // 添加函数消息
  addFunctionMessage(content:string) {
    this.messageList.push(new ChatCompletionFunctionMessageParam(content))
  }

  // 添加工具消息
  addToolMessage(content:string,name:string,toolCallId:string) {
    this.messageList.push(new ChatCompletionToolMessageParam(content,name,toolCallId))
  }

  addMessage(message: ChatCompletionMessage) {
    this.messageList.push(message)
  }

  // 进行一次对话
  // 使用代理模式，否则@State 无法更新
  // async chat(messages:Array<ChatItem>,inputText:string) {
  chat(data:AiDialogData) {

    console.debug("Openai", "chat", data.inputText)


    // 添加用户信息消息
    this.messageList.push(new ChatCompletionUserMessageParam(data.inputText))

    // 添加一个新的聊天项到消息列表中，并发送更新后的消息列表事件
    let messageLength = data.messages.length
    data.messages.push(new ChatItem())
    data.messages[messageLength-1].id = messageLength
    data.messages[messageLength-1].content = ""
    getContext(this).eventHub.emit('messages', data.messages);
    console.debug("Openai", "chat", JSON.stringify(data.messages))
    console.debug("Openai", "chat", JSON.stringify(this.messageList))


    data.inputText = ""

    // 通过流式处理获取聊天完成信息
    this.getCompletionByStream((response) => {
      console.log(JSON.stringify((response)));
      let resp = response as ChatCompletionChunk[]

      // 遍历响应中的每个消息块，并追加内容到消息列表的最后一个元素中
      for (let chunck of resp) {
        if (chunck?.choices[0]?.delta?.content) {

          data.messages[messageLength-1].content += chunck.choices[0].delta.content as string
          console.log("消息块：",chunck.choices[0].delta.content as string)

        }
      }

      console.debug("Openai", "getCompletionByStream", data.messages[messageLength-1].content)



      data.inputText = ""
      getContext(this).eventHub.emit('inputText', data.inputText);
      getContext(this).eventHub.emit('messages', data.messages);

    })

    console.debug("Openai", "chat", "end")

  }



  // 获取初始化的模型参数，用于构造请求
  getModelParams(isStream:boolean): IChatCompletionPostData {

    let tools = new Tool().getTools();

    console.debug("tools",JSON.stringify(tools));


    return {
      messages: this.messageList,
      // model: "gpt-4o-mini",
      model: "qwen-max",
      stream: isStream,
      tools: tools
    }
  }


  // 调用工具
  callFunction(functionName:string, functionArguments:string,callback: (res:string)=>void) {
		new Tool().callFunction(functionName,functionArguments,callback);
	}


  // 获取非流式数据
  async getCompletion(chatFunction:(res:ChatCompletion | ChatCompletionChunk[])=>void) {

    console.debug("Openai", "getCompletion =================================")
    console.debug("Openai", "getCompletion", JSON.stringify(this.getModelParams(false)))
    console.debug("Openai", "getCompletion", JSON.stringify(this.messageList))
    console.debug("Openai", "getCompletion =================================")


    let response = await this.openaiClient.chat.completions.create(this.getModelParams(false))
    chatFunction(response)
  }

  // 获取流式数据并进行处理
  async getCompletionByStream(
    streamFunction:(res:ChatCompletion |ChatCompletionChunk| ChatCompletionChunk[])=>void,
    beforeResponse:()=>void = ()=>{},
    processTotalResult:(totalResult:ChatCompletion)=> void = ()=>{},
    afterResponse:()=>void = ()=>{}
  ) {

    beforeResponse();

    let totalResult:ChatCompletion|undefined = undefined;

    this.openaiClient.chat.completions.createStream(
      this.getModelParams(true),
      (messages:ChatCompletionChunk[])=>{


      // 将一个ChatcompletionChunk数组转换为一堆ChatCompletion
      for (let i = 0; i < messages.length; i++) {

        let message = this.chatCompletionChunk2ChatCompletion(messages[i]);

        if (totalResult != undefined) {
          if (message.choices[0].message.content != undefined) {
            totalResult.choices[0].message.content = (totalResult.choices[0].message.content as string) + message.choices[0].message.content;
          }
        } else {
          totalResult = message;
        }

        if(message.choices[0].message.tool_calls != undefined){
          if(totalResult.choices[0].message.tool_calls == undefined){
            totalResult.choices[0].message.tool_calls = [];
          }else{
            for(let j = 0; j < message.choices[0].message.tool_calls.length; j++){

              if(totalResult.choices[0].message.tool_calls.length <= j){
                totalResult.choices[0].message.tool_calls.push(new ChatCompletionMessageToolCall());
              }

              if(messages[i].choices[0].delta.tool_calls[j] == undefined ||
                messages[i].choices[0].delta.tool_calls[j] == null){
                continue;
              }

              let toolCall:ChatCompletionMessageToolCall = JSON.parse(
                JSON.stringify(messages[i].choices[0].delta.tool_calls[j])
              );


              if(toolCall.function.name != undefined && toolCall.function.name != ""){
                totalResult.choices[0].message.tool_calls[j].function.name = toolCall.function.name;
              }

              if (toolCall.function.arguments != undefined) {
                totalResult.choices[0].message.tool_calls[j].function.arguments += toolCall.function.arguments;
              }
            }
          }
        }


        streamFunction(message);


      }

    })


    emitter.on("httpEnd",()=>{

      emitter.off("httpEnd");

      if (totalResult != undefined) {
        processTotalResult(totalResult);
      }

      setTimeout(() => {
        afterResponse();
      }, 300);

      // afterResponse()


    })

  }

  /**
   * 将ChatCompletionChunk转换为ChatCompletion
   * @param originalMessage 原先的消息
   * @returns 转换后的消息
   */
  chatCompletionChunk2ChatCompletion(originalMessage:ChatCompletionChunk):ChatCompletion{


    console.debug("Openai", "chatCompletionChunk2ChatCompletion", JSON.stringify(originalMessage))


    let message: ChatCompletion;
    let choices: Choice[] = []


    if(originalMessage.choices == undefined){
      return {
        id: originalMessage.id,
        created: originalMessage.created,
        model: originalMessage.model,
        object: originalMessage.object,
        system_fingerprint: originalMessage.system_fingerprint,
        choices: []
      }
    }

    for (let j = 0; j < originalMessage.choices.length; j++) {

      let originalDelta = originalMessage.choices[j].delta;

      let delta = new ChatCompletionMessage();


      let originalToolCalls = JSON.stringify(originalDelta.tool_calls);

      if (originalToolCalls == undefined) {
        originalToolCalls = "[]";
      }

      let toolCalls: ChatCompletionMessageToolCall[] = JSON.parse(originalToolCalls);


      originalDelta.function_call
      delta = {
        role: originalDelta.role as string,
        // name: "",
        content: originalDelta.content as string,

        // function_call: {
        //   arguments: originalDelta.function_call?.arguments as string,
        //   name: originalDelta.function_call?.name as string
        // },
        tool_calls: toolCalls
      }

      let choice: Choice = {
        finish_reason: originalMessage.choices[j].finish_reason as string,
        index: originalMessage.choices[j].index,
        message: delta,
        logprobs: originalMessage.choices[j].logprobs
      }
      choices.push(choice)
    }



    message = {
      id: originalMessage.id,
      created: originalMessage.created,
      model: originalMessage.model,
      object: originalMessage.object,
      system_fingerprint: originalMessage.system_fingerprint,
      choices: choices
    }


    return message;
  }


}

export default new Openai()
