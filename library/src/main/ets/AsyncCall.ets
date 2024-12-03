import axios, { AxiosHeaders, AxiosInstance, AxiosResponse } from '@ohos/axios'
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ChatCompletion } from './ChatCompletion'
import { ChatCompletionChunk } from './ChatCompletionChunk'
import { IChatCompletionMessageParam } from './ChatCompletionMessageParam'
import { CommonTool } from './CommonTool'
import {
  ChatCompletionFunctionCallOptionParam,
  ChatCompletionNamedToolChoiceParam,
  ChatCompletionToolParam,
  ResponseFormat
} from './Function'
import { RequestConfig } from './OpenAI'
import { util } from '@kit.ArkTS';

export interface IChatCompletionPostData {
  messages: IChatCompletionMessageParam[],
  model?: string,
  frequency_penalty?: number,
  function_call?: string | ChatCompletionFunctionCallOptionParam,
  functions?: Iterable<Function>,
  logit_bias?: Map<string, number>,
  logprobs?: boolean,
  max_tokens?: number,
  n?: number,
  presence_penalty?: number,
  response_format?: ResponseFormat,
  seed?: number,
  stop?: string | string[],
  stream?: boolean,
  temperature?: number,
  tool_choice?: string | ChatCompletionNamedToolChoiceParam,
  tools?: Iterable<ChatCompletionToolParam>,
  top_logprobs?: number,
  top_p?: number,
  user?: string,

  //Use the following arguments if you need to pass additional parameters to the API that aren't available via kwargs.
  // The extra values given here take precedence over values defined on the client or passed to this method.
  //extra_headers?: Map<string, string>,
  //extra_query?: Map<string, string>,
  //extra_body?: Body | None = None,
  timeout?: number
}

export class ChatCompletions {
  _client: RequestConfig
  with_raw_response: RawResponseCompletions

  constructor(_client: RequestConfig) {
    this._client = _client
    this.with_raw_response = new RawResponseCompletions(this._client);
  }



  public static parseDataToJson(data: IChatCompletionPostData): string {
    let postData : Map<string,object> = new Map();
    if (data.messages) {
      postData["messages"] = data.messages;
    }
    if (data.model) {
      postData["model"] = data.model
    }
    if (data.frequency_penalty) {
      postData["frequency_penalty"] = data.frequency_penalty
    }
    if (data.function_call) {
      postData["function_call"] = data.function_call
    }
    if (data.functions) {
      postData["functions"] = data.functions
    }
    if (data.logit_bias) {
      postData["logit_bias"] = data.logit_bias
    }
    if (data.logprobs) {
      postData["logprobs"] = data.logprobs
    }
    if (data.max_tokens) {
      postData["max_tokens"] = data.max_tokens
    }
    if (data.n) {
      postData["n"] = data.n
    }
    if (data.presence_penalty) {
      postData["presence_penalty"] = data.presence_penalty
    }
    if (data.response_format) {
      postData["response_format"] = data.response_format
    }
    if (data.seed) {
      postData["seed"] = data.seed
    }
    if (data.stop) {
      postData["stop"] = data.stop
    }
    if (data.stream) {
      postData["stream"] = data.stream
    }
    if (data.temperature) {
      postData["temperature"] = data.temperature
    }
    if (data.tool_choice) {
      postData["tool_choice"] = data.tool_choice
    }
    if (data.tools) {
      postData["tools"] = data.tools
    }
    if (data.top_logprobs) {
      postData["top_logprobs"] = data.top_logprobs
    }
    if (data.top_p) {
      postData["top_p"] = data.top_p
    }
    if (data.user) {
      postData["user"] = data.user
    }
    return JSON.stringify(postData);
  }



  createStream(
    data: IChatCompletionPostData,
    onMessage: (messages: ChatCompletionChunk[]) => void,
  ) {


    let url: string = ""
    if (data.model && this._client.baseURL?.indexOf("openai.azure.com") >= 0 && !this._client.baseURL.endsWith(data.model)) {
      url = `${this._client.baseURL}/deployments/${data.model}/chat/completions${CommonTool.encodeUrlParams(this._client.params as Record<string, string>)}`
    } else {
      url = `${this._client.baseURL}/chat/completions${CommonTool.encodeUrlParams(this._client.params as Record<string, string>)}`
    }
    let timeout = 300;
    if (data.timeout) {
      timeout = data.timeout
    }

    let jsonStr = ChatCompletions.parseDataToJson(data);

    // 创建一个http请求
    let httpRequest = http.createHttp();

    httpRequest.on('headersReceive', (header: Object) => {
      console.debug('发送的消息头: ' + JSON.stringify(header));
    });

    httpRequest.on('dataReceive', (data: ArrayBuffer) => {

      const resView = new Uint8Array(data);

      let textDecoder = util.TextDecoder.create('utf-8')
      let resStr = textDecoder.decodeToString(resView);

      console.debug("receiver data: " + resStr);

      let respMsgs: ChatCompletionChunk[] = []

      for (const line of resStr.split(/[\r\n]+/)) {

        // 判断有没有data:字段
        if (line.indexOf("data:") < 0) {
          continue;
        }

        let msgJson = line.split("data:")[1]
        if (msgJson.indexOf("[DONE]") >= 0) {
          break;
        }
        respMsgs.push(JSON.parse(msgJson));
      }


      onMessage(respMsgs)


    });
    // 用于订阅HTTP流式响应数据接收完毕事件
    httpRequest.on('dataEnd', () => {
      console.debug('消息传递完成！！！No more data in response, data receive end');
    });

    // 用于订阅HTTP流式响应数据接收进度事件
    class Data {
      receiveSize: number = 0;
      totalSize: number = 0;
    }

    httpRequest.on('dataReceiveProgress', (data: Data) => {
      console.log("dataReceiveProgress receiveSize:" + data.receiveSize + ", totalSize:" + data.totalSize);
    });


    let streamInfo: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,  // 可选，默认为http.RequestMethod.GET
      header: this._client.headers,
      // 当使用POST请求时此字段用于传递请求体内容，具体格式与服务端协商确定
      extraData: jsonStr,
      expectDataType:  http.HttpDataType.STRING,// 可选，指定返回数据的类型
    }

    // 填写HTTP请求的URL地址，可以带参数也可以不带参数。URL地址需要开发者自定义。请求的参数可以在extraData中指定
    httpRequest.requestInStream(url, streamInfo).then((data: number) => {
      console.info("requestInStream OK!");
      console.info('ResponseCode :' + JSON.stringify(data));
      // 取消订阅HTTP响应头事件
      httpRequest.off('headersReceive');
      // 取消订阅HTTP流式响应数据接收事件
      httpRequest.off('dataReceive');
      // 取消订阅HTTP流式响应数据接收进度事件
      httpRequest.off('dataReceiveProgress');
      // 取消订阅HTTP流式响应数据接收完毕事件
      httpRequest.off('dataEnd');
      // 当该请求使用完毕时，调用destroy方法主动销毁
      httpRequest.destroy();
    }).catch((error: Error) => {
      console.error(JSON.stringify(error));
      console.error(error.message)

    });


  }


  create(
    data: IChatCompletionPostData
  ): Promise<ChatCompletion | ChatCompletionChunk[]> {

    return new Promise<ChatCompletion | ChatCompletionChunk[]>((resolve, reject) => {

      let url: string = ""
      if (data.model && this._client.baseURL?.indexOf("openai.azure.com") >= 0 && !this._client.baseURL.endsWith(data.model)) {
        url = `${this._client.baseURL}/deployments/${data.model}/chat/completions${CommonTool.encodeUrlParams(this._client.params as Record<string, string>)}`
      } else {
        url = `${this._client.baseURL}/chat/completions${CommonTool.encodeUrlParams(this._client.params as Record<string, string>)}`
      }
      let timeout = 300;
      if (data.timeout) {
        timeout = data.timeout
      }

      let jsonStr = ChatCompletions.parseDataToJson(data);



      axios.request<string|ChatCompletion, AxiosResponse<string|ChatCompletion>>({
        method: "post",
        url: url,
        data: jsonStr,
        headers: this._client.headers,
        timeout: timeout * 1000
      })
        .then((response: AxiosResponse<string|ChatCompletion>) => {
          console.info(JSON.stringify(response));
          let respMsgs: ChatCompletionChunk[] = []

          if (response.headers['content-type'] == 'text/event-stream') {
            // console.info(JSON.stringify(response));
            for (const line of (response.data as string).split(/[\r\n]+/)) {
              // console.log(line);
              let msgJson = line.split("data:")[1]
              if (msgJson.indexOf("[DONE]") >= 0) {
                break;
              }
              respMsgs.push(JSON.parse(msgJson));
            }
            resolve(respMsgs)
          }
          else {
            let respData: ChatCompletion = (response.data as ChatCompletion)
            resolve(respData)
          }

        })
        .catch((error: Error) => {
          console.error(JSON.stringify(error));
          console.error(error.message)
          reject(error)
        });


    })
  }
}

class RawResponse {
  headers: Record<string, string|number|object|boolean|undefined|null>
  private _data: ChatCompletion | ChatCompletionChunk[]

  constructor(data: ChatCompletion | ChatCompletionChunk[], headers: Record<string, string|number|object|boolean|undefined|null>) {
    this._data = data;
    this.headers = headers;
  }

  parse(): ChatCompletion | ChatCompletionChunk[] {
    return this._data;
  }
}

export class RawResponseCompletions {
  _client: RequestConfig

  constructor(_client: RequestConfig) {
    this._client = _client
  }

  create(
    data: IChatCompletionPostData
  ): Promise<RawResponse> {
    return new Promise<RawResponse>((resolve, reject) => {
      let url: string = ""
      if (data.model && this._client.baseURL.indexOf("openai.azure.com") >= 0 && !this._client.baseURL.endsWith(data.model)) {
        url = `${this._client.baseURL}/deployments/${data.model}/chat/completions${CommonTool.encodeUrlParams(this._client.params as Record<string, string>)}}`
      } else {
        url = `${this._client.baseURL}/chat/completions${CommonTool.encodeUrlParams(this._client.params as Record<string, string>)}`
      }
      let timeout = 300;
      if (data.timeout) {
        timeout = data.timeout
      }

      let jsonStr = ChatCompletions.parseDataToJson(data);
      axios.request<string, AxiosResponse<string>>({
        method: "post",
        url: url,
        data: jsonStr,
        headers: this._client.headers,
        timeout: timeout * 1000
      })
        .then((response: AxiosResponse<string>) => {
          console.info(JSON.stringify(response));
          let respMsgs: ChatCompletionChunk[] = []

          if (response.headers['content-type'] == 'text/event-stream') {
            // console.info(JSON.stringify(response));
            for (const line of response.data.split(/[\r\n]+/)) {
              // console.log(line);
              let msgJson = line.split("data:")[1]
              if (msgJson.indexOf("[DONE]") >= 0) {
                break;
              }
              respMsgs.push(JSON.parse(msgJson));
            }
            resolve(new RawResponse(respMsgs, response.headers))
          }
          else {
            let respData: ChatCompletion = JSON.parse(response.data)
            resolve(new RawResponse(respData, response.headers))
          }

        })
        .catch((error:Error) => {
          console.info(JSON.stringify(error));
          reject(error)
        });


    });
  }
}

export class Chat {
  completions: ChatCompletions

  constructor(_client: RequestConfig) {
    if (_client) {
      this.completions = new ChatCompletions(_client)
    }else{
      this.completions = new ChatCompletions(new RequestConfig("https://api.openai.com/v1"))
    }
  }
}