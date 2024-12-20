
import Openai from '../common/utils/Openai'
import CommonConstants from '../common/constants/CommonConstants';
import ChatItem from '../viewmodel/ChatItem';
import { ChatCompletion } from '@adrian_wang/openai';

@Observed
export class AiDialogData{


  public messages: Array<ChatItem>;
  public inputText: string;
  public isLoading: boolean;
  public loadingString: string;

  constructor() {
    this.messages = [];
    this.inputText = '';
    this.isLoading = false;
    this.loadingString = '加载中...';
  }
}


@CustomDialog
export struct AiDialogComponent {
  controller?: CustomDialogController;

  @State data: AiDialogData = new AiDialogData();

  loadingStrings: string[] = [
    '加载中...',
    '加载中..',
    '加载中.',
  ]

  loadingStringIndex: number = 0;


  // 构建方法，用于创建和配置用户界面组件
  build() {
    // 定义一个列组件，包含一个图像，并且点击该图像可以关闭当前控制器
    Column() {
      Scroll() {
        Column(){


          if (this.data.isLoading){
            Text(this.data.loadingString)
              .backgroundColor('#f0f0f0')
              .borderRadius(10)
              .padding(10);
          }


          ForEach(this.data.messages, (message:ChatItem) => {
            //message.id 表示消息 id
            //message.name 表示消息发送名字
            //message.avatar 表示消息发送者头像
            //message.content 表示消息内容
            //message.time 表示消息发送时间
            //message.isSelf 表示是否是用户自己发送的
            //message.isShowTime 表示是否显示时间
            //message.isShowAvatar 表示是否显示头像
            /**
             * TODO 根据已有的消息渲染消息列表，要求美观点，消息样式就是 ChatList
             * TODO 用户的消息显示在右边，AI 的消息显示在左边
             * TODO 时间显示在消息下方，并且只显示一次，如果连续两个消息时间相同，则不显示时间
             * TODO 如果是 AI 的函数调用，则显示正在进行函数调用进度，且需要描述出调用的具体函数
             * TODO 如果调用完成，需要让用户选择要执行的操作，即显示两个按钮，应用或者放弃
             */


            Text(message.isFunctionCall ?
              '正在调用函数：' + message.functionName + '...' + message.functionProgress + '%' + '调用结果：' + message.functionResult
              : message.content)
              .backgroundColor(message.content.startsWith('AI:')? '#f0f0f0' : '#e0e0e0')
              .borderRadius(10)
              .padding(10);
          }, (item:ChatItem) => JSON.stringify(item));
        }

      }
      .height('80%')
      .border({
        width: 1,
        color: '#e0e0e0'
      })
      Row() {

        TextArea({text:$$this.data.inputText, placeholder: '输入对话...' })
          .focusable(!this.data.isLoading)
          .width('70%')

        Button(){
          Image($rawfile('send.svg'))// 设置图像的宽度
            .width($r('app.float.button_image_width'))// 设置图像的高度
            .height($r('app.float.button_image_height'))// 当图像被点击时，关闭当前控制器（如果存在）
        }
        .width($r('app.float.button_width'))
        .height($r('app.float.button_height'))
        .onClick(() => {

          if (this.data.inputText === '') {
            console.debug("请输入内容")
            return;
          }


          if (this.data.inputText.trim()!== '') {


            let content = this.data.inputText.valueOf();

            // 清空输入框
            this.data.inputText = ""
            // 显示加载中
            this.data.isLoading = true


            let length = this.data.messages.length;
            this.data.messages.push({
              id: length,
              name: '我',
              avatar: '',
              content: content,
              time: '',
              isSelf: true,
              isShowTime: false,
              isFunctionCall: false,
              isShowAvatar: false,
              functionProgress: 0,
              functionName: '',
              functionArguments: '',
              functionResult: ''
            });

            //TODO 工具调用相关操作需要实现


            // 添加用户信息消息
            Openai.addUserMessage(content);

            let message:Record<string,string> = {
              "name" : "",
              "content" : content,
              "role" : "user"
            }

            getContext(this).eventHub.emit('userMessageSend', message)

          }

        });

        Button(){
          Image($rawfile('clear.svg'))// 设置图像的宽度
            .width($r('app.float.button_image_width'))// 设置图像的高度
            .height($r('app.float.button_image_height'))// 当图像被点击时，关闭当前控制器（如果存在）
        }
        .width($r('app.float.button_width'))
        .height($r('app.float.button_height'))
        .onClick(() => {
          this.data.messages = [];
          Openai.messageList = [];
        });
      }
      .height($r('app.float.component_size_M'))
      // 设置布局权重为充满整个屏幕
      .layoutWeight(CommonConstants.FULL_SIZE)
      // 设置底部、左边和右边的内边距为字体大小L
      .padding({
        bottom: $r('app.float.font_size_L'),
        left: $r('app.float.font_size_L'),
        right: $r('app.float.font_size_L')
      })
      // 设置内容对齐方式为末尾对齐
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Bottom)

    }
    // 设置宽度为充满整个屏幕
    .width(CommonConstants.FULL_WIDTH)
    // 设置高度为对话框标准高度
    .height(CommonConstants.DIALOG_HEIGHT)
    // 设置圆角边框，只在顶部的左右两个角有圆角
    .borderRadius({ topLeft: $r('app.float.font_size_L'), topRight: $r('app.float.font_size_L') })
    // 设置背景颜色为白色
    .backgroundColor(Color.White)
    // 设置对齐方式为屏幕的右下角
    .align(Alignment.BottomEnd)
  }


  aboutToAppear(): void {

    let toolCallId:string = "";
    let functionName:string = "";
    let functionArguments:string = "";
    let currentMessage: ChatItem;
    let isToolCall:boolean = false;

    let chatOperation = (tips:string,nextStep:string)=>{
      console.debug("tips:",tips);

      // 添加一个新的聊天项到消息列表中，并发送更新后的消息列表事件
      let messageLength = this.data.messages.length;

      this.data.messages.push({
        id: messageLength,
        name: 'AI',
        avatar: '',
        content: "加载中...",
        time: '',
        isSelf: false,
        isShowTime: false,
        isFunctionCall: false,
        isShowAvatar: false,
        functionProgress: 0,
        functionName: '',
        functionArguments: '',
        functionResult: ''
      })

      // 通过流式处理获取聊天完成信息
      Openai.getCompletionByStream((response) => {

        let resp = response as ChatCompletion


        this.data.loadingString = this.loadingStrings[this.loadingStringIndex]
        this.loadingStringIndex = (this.loadingStringIndex + 1) % this.loadingStrings.length

        console.debug("接收到消息",JSON.stringify(resp.choices[0].message))


        for (let i = 0; i < resp.choices.length; i++) {
          let choice = resp.choices[i]


          if (
          //(choice.finish_reason === "function_call" || choice.finish_reason === "tool_calls") &&
            choice.message.tool_calls !== undefined &&
              choice.message.tool_calls.length > 0
          ) {
            isToolCall = true
            let functionCall = choice.message.tool_calls[0]

            // 显示函数调用进度条
            this.data.messages[messageLength].isFunctionCall = true
            this.data.messages[messageLength].functionProgress = 0


            if(functionCall.function.name != undefined && (functionName == undefined || functionName == "")){
              // 显示函数调用名称
              this.data.messages[messageLength].functionName = functionCall.function.name
              functionName = functionCall.function.name
            }

            if (functionCall.function.arguments != undefined) {
              this.data.messages[messageLength].functionArguments += functionCall.function.arguments
              functionArguments += functionCall.function.arguments
            }

            if (toolCallId == "" && functionCall.id != undefined) {
              toolCallId = functionCall.id;
            }

          }else{
            // 当前函数调用完成
            // 隐藏加载中
            this.data.isLoading = false
          }


          if (choice.message.content != undefined) {
            // 无论如何需要添加消息
            this.data.messages[messageLength].content += choice.message.content
          }

        }

        currentMessage  = this.data.messages[messageLength];

        console.debug("currentMessage",JSON.stringify(currentMessage))

      },()=>{
        // 开始调用前先清空“加载中”
        this.data.messages[messageLength].content = ""
      },(totalResponse)=>{
        console.debug("消息生成结束，将消息天假到最后")
        // 添加消息到消息列表便于显示
        Openai.addMessage(totalResponse.choices[0].message)
      },()=>{
        console.log("函数调用开始",JSON.stringify(currentMessage))

        if(isToolCall){

          console.debug("调用函数",functionName,functionArguments);

          //调用具体函数
          Openai.callFunction(functionName,functionArguments,(res)=>{
            console.debug("调用函数返回：",res)


            // 修改函数调用结果
            console.debug("显示调用结果")
            this.data.messages[messageLength].functionResult = res

            console.debug("添加工具消息")

            // 添加工具信息消息
            Openai.addToolMessage(res,currentMessage.functionName,toolCallId)

            console.log("函数调用完成返回")

            isToolCall = false;
            functionName = "";
            functionArguments = "";
            toolCallId = "";

            getContext(this).eventHub.emit(nextStep);
          });


        }
      })

      console.debug("Openai", "chat", "end")
    }



    // 对话事件
    getContext(this).eventHub.on("userMessageSend",() => {

      // 延迟一秒发送消息
      setTimeout(()=>{
        chatOperation("用户消息发送完成，开始对话","toolCallEnd");
      },500)

    })

    getContext(this).eventHub.on("toolCallEnd",()=>{
      setTimeout(()=>{
        chatOperation("工具调用结束，继续下一步","userMessageSend");
      },500)

    })

  }



}

// ai 对话气泡

