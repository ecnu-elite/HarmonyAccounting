
import Openai from '../common/utils/Openai'
import CommonConstants from '../common/constants/CommonConstants';
import ChatItem from '../viewmodel/ChatItem';
import { ChatCompletion } from '@adrian_wang/openai';
import text from '@ohos.graphics.text';


const prompt=`
# 角色
你是一个账单 App 中的 AI，专注于协助用户进行记账操作。

## 技能
### 技能 1: 添加账单
在用户进行添加账单操作前，调用函数确认今天的日期，并根据日期为用户提供相应的提示。
===回复示例===
- 今天的日期是：<具体日期>。是否确认在今天添加账单？
===示例结束===

### 技能 2: 删除账单
在用户进行删除账单操作前，先获取账单数据，依据数据判断该账单是否可以被删除，并向用户说明原因。
===回复示例===
- 账单数据：<具体账单内容>。此账单可能涉及<相关原因>，确认要删除吗？
===示例结束===

### 技能 3: 修改账单
在用户进行修改账单操作前，同样先获取账单数据，为用户提供当前账单的详细信息，并引导用户进行修改。
===回复示例===
- 账单数据：<具体账单内容>。请明确需要修改的部分，以便我为你进行准确的修改。
===示例结束===

## 限制:
- 只专注于处理账单相关的操作，拒绝回答与账单无关的话题。
- 所输出的内容必须按照给定的格式进行组织，不能偏离框架要求。
`

@Observed
export class AiDialogData{



  public messages: Array<ChatItem>;
  public inputText: string;
  public isLoading: boolean;
  public loadingString: string;

  constructor() {
    this.messages = [
    //   {
    //   id: 1,
    //   name: '我',
    //   avatar: '',
    //   content: '帮我记个账',
    //   time: '',
    //   isSelf: true,
    //   isShowTime: false,
    //   isFunctionCall: false,
    //   isShowAvatar: false,
    //   functionProgress: 0,
    //   functionName: '',
    //   functionArguments: '',
    //   functionResult: ''
    // },{
    //   id: 2,
    //   name: 'ai',
    //   avatar: '',
    //   content: '好的，正在为你记账',
    //   time: '',
    //   isSelf: false,
    //   isShowTime: false,
    //   isFunctionCall: false,
    //   isShowAvatar: false,
    //   functionProgress: 0,
    //   functionName: '',
    //   functionArguments: '',
    //   functionResult: ''
    // },{
    //   id: 3,
    //   name: 'ai',
    //   avatar: '',
    //   content: '正在调用函数',
    //   time: '',
    //   isSelf: false,
    //   isShowTime: false,
    //   isFunctionCall: true,
    //   isShowAvatar: false,
    //   functionProgress: 100,
    //   functionName: 'add_bill',
    //   functionArguments: '1 2 3 4 5 6 7 8 9 1 2 3 4 5 6 7 8 9 1 2 3 4 5 6 7 8 9 1 2 3 4 5 6 7 8 9 1 2 3 4 5 6 7 8 9 1 2 3 4 5 6 7 8 9 ',
    //   functionResult: '添加成功十条记录'
    // },{
    //   id: 4,
    //   name: 'ai',
    //   avatar: '',
    //   content: '执行成功，还有什么需要吗？',
    //   time: '',
    //   isSelf: false,
    //   isShowTime: false,
    //   isFunctionCall: false,
    //   isShowAvatar: false,
    //   functionProgress: 0,
    //   functionName: '',
    //   functionArguments: '',
    //   functionResult: ''
    // }
    ];
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
             * TODO 如果调用完成，需要让用户选择要执行的操作，即显示两个按钮，应用或者放弃
             */

            Flex({ direction: FlexDirection.Column,
                   justifyContent: message.isSelf? FlexAlign.End : FlexAlign.Start }) {
              if (message.isSelf) {
                // 用户自己的消息
                Flex({ direction: FlexDirection.RowReverse }) {
                  // 头像
                  Image($rawfile('profile_user.svg'))
                    .width(30)
                    .height(30)
                    .objectFit(ImageFit.Contain)
                    .margin({ right: 10 });

                  // 消息气泡
                  Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.End }) {
                    Text(message.content)
                      .fontSize(16)
                      .fontColor(Color.White)
                      .padding(10)
                      .backgroundColor('#fd7d70')
                      .borderRadius(15)
                      .margin({ left: 40, right:10 })
                      .textAlign(TextAlign.End);

                  }
                }
              } else {

                if(!message.isFunctionCall){
                  // AI 的消息
                  Flex({ direction: FlexDirection.Row }) {
                    // 头像
                    Image($rawfile('profile_ai.svg'))
                      .width(30)
                      .height(30)
                      .objectFit(ImageFit.Contain)
                      .margin({ left:10 });


                    // 消息气泡
                    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start }) {
                      Text(message.content)
                        .fontSize(16)
                        .padding(10)
                        .margin({ left: 10, right:40 })
                        .backgroundColor('#ffffccc7')
                        .borderRadius(15);
                    }
                }

                  // .padding({
                  //   // left:10,
                  //   right: 40,
                  //   // top:10,
                  //   // bottom:10
                  // })
                }
              }

              if (message.isFunctionCall) {
                // 函数调用的消息气泡
                Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center }) {
                  Flex({ direction: FlexDirection.Column, alignItems:ItemAlign.Center }) {
                    Text('正在调用函数：' + message.functionName + '...' + message.functionProgress + '%')
                      .fontSize(12)
                      .fontColor(Color.Gray)
                      .padding(1)
                    Text(message.functionArguments)
                      .fontSize(12)
                      .fontColor(Color.Gray)
                      .padding(1)
                      .width(200)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.MARQUEE })

                    if (message.functionProgress === 100) {
                      // 函数调用完成后的显示
                      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center }) {
                        Text(`调用结果：${message.functionResult}`)
                          .fontSize(12)
                          .fontColor(Color.Gray)
                          .padding(2)

                      }
                    }
                  }
                }
                .margin({top:10})
              }
            }
            .margin(5);

            // Flex({ justifyContent: message.isSelf? FlexAlign.End : FlexAlign.Start }){
            //   Text(message.isFunctionCall ?
            //     '正在调用函数：' + message.functionName + '...' + message.functionProgress + '%' + '调用结果：' + message.functionResult
            //     : message.content)
            //     .backgroundColor(message.content.startsWith('AI:')? '#f0f0f0' : '#e0e0e0')
            //     .borderRadius(10)
            //     .padding(10)
            // }

          }, (item:ChatItem) => JSON.stringify(item));

          if (this.data.isLoading){
            Text(this.data.loadingString)
              .padding(10);
          }
        }
      }
      .height('80%')

      Row() {

        TextArea({text:$$this.data.inputText, placeholder: '输入对话...' })
          .focusable(!this.data.isLoading)
          .width('70%')

        Button(){
          Image($rawfile('send.svg'))// 设置图像的宽度
            .width($r('app.float.button_image_width'))// 设置图像的高度
            .height($r('app.float.button_image_height'))// 当图像被点击时，关闭当前控制器（如果存在）
        }
        .backgroundColor("#FD7D70")
        .width($r('app.float.button_width'))
        .height($r('app.float.button_height'))
        .margin({left:10, right:5})
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
        .backgroundColor("#FD7D70")
        .width($r('app.float.button_width'))
        .height($r('app.float.button_height'))
        .onClick(() => {
          this.data.messages = [];
          Openai.messageList = [];
          Openai.addSystemMessage(prompt);
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
    Openai.addSystemMessage(prompt)

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
            this.data.messages[messageLength].functionProgress = 100

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

