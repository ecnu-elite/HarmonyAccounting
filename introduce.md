# HarmonyAccounting 项目结构介绍

## 一、项目总体结构

- library/
  - src/
    - main/
      - ets/
        - Function.ets：与工具类方法调用相关的定义文件
        - ChatCompletionMessageParam.ets：存放消息参数定义
        - ChatCompletion.ets：对话消息结构与处理
        - AsyncCall.ets：封装异步执行逻辑
      - ...（其它主代码目录）
  - Index.ets：库的主入口文件，与整体加载流程关联
  - ...（库相关的配置、资源等）
- entry/
  - src/
    - main/
      - ets/
        - common/
          - utils/
            - Openai.ets：建构 OpenAI 接口与流式调用处理的核心
          - ...（其它主代码目录）
        - view/
          - AiDialogComponent.ets：AI 对话框组件，结合 Openai.ets 实现消息交互
          - ...（其它主代码目录）
        - viewmodel/
          - ChatItem.ets：AI 对话消息的模型，用于界面显示
          - ...（其它主代码目录）
        - pages/
          - MainPage.ets：应用主页面，整合账单与 AI 对话框等交互
          - ...（其它主代码目录）
    - ...（其它主代码目录）
- ...（其它根目录文件夹）

## 二、library/src/main/ets 模块概述

1. Function.ets

   - 定义项目运行所需的函数与工具调用，用于扩展对话或功能。

2. ChatCompletionMessageParam.ets

   - Core：对对话消息中的参数进行封装，规范化消息传递格式。

3. ChatCompletion.ets

   - 管理对话消息的结构，处理对话生成流程，实现解析与流式响应。

4. AsyncCall.ets
   - 通用异步调用工具，提供统一的请求和响应回调机制。

## 三、常见功能与交互流程

- MainPage.ets 提供账单管理界面、调起对话框等功能。
- AiDialogComponent.ets 与 Openai.ets 协同工作，通过 Stream API 进行实时对话。
- Openai.ets 封装调用 ChatCompletion 等功能模块，并管理消息列表与流式输出。
- Function.ets、ChatCompletionMessageParam.ets、ChatCompletion.ets 与 AsyncCall.ets 等公共库文件，负责工具调用、消息结构以及异步加载。

## 四、后续可拓展方向

- 深化 AI 对话场景，如增加更多工具拓展实现。
- 优化数据库查询与性能调度。
- 引入更多可视化组件，加强统计分析功能。

## 五、PPT 演示大纲

### 1. 项目概述

- 定位：HarmonyAccounting 提供账单管理与实时 AI 对话功能
- 特色：UI 界面轻量化、嵌入式 AI 辅助
- 目标：简化财务处理，提升用户交互体验

### 2. 系统模块

- UI 展示层：entry/src/main/ets/view 与 pages
- 业务逻辑层：entry/src/main/ets/viewmodel
- 数据处理与存储层：entry/src/main/ets/common/database
- AI 交互层：library/src/main/ets + entry/src/main/ets/common/utils

### 3. AI 对话流程

- 用户发起交互 → 调用 Openai.ets → ChatCompletion.ets 流式返回 → AiDialogComponent.ets 动态显示
- 支持多轮对话及工具调用

### 4. 账单管理流程

- 主界面 MainPage.ets → 数据库 AccountTable.ets → 账单信息展示及编辑

### 5. 统计与可视化

- 支持月度或周度数据分组，结合 McPieChart/McBarChart
- 强化用户对数据信息的把控

### 6. 后续演示要点

- 现场展示账单增删改查
- AI 实时问答场景，展示流式输出与工具调用

## 六、详细文件说明

### 1. library/src/main/ets

1. Function.ets

   - 提供可复用的功能模块与工具方法，协助对话逻辑实现
   - 主要与 ChatCompletionMessageParam.ets 等文件配合使用，以便在对接外部 API 时灵活调用

2. ChatCompletionMessageParam.ets

   - 定义对话中消息的关键参数与结构格式
   - 帮助 ChatCompletion.ets 识别用户、系统或函数等不同消息角色

3. ChatCompletion.ets

   - 负责管理对话生成、多轮交互及调用 Function.ets 中的逻辑
   - 提供详尽的 ChatCompletionMessage 数据处理与工具对接

4. AsyncCall.ets
   - 展现项目的异步调用与数据流管理思路
   - 与 ChatCompletion 等协同，实现流式数据返回和消息同步更新

### 2. library/Index.ets

- 整个库的主入口，初始化核心组件、加载资源配置
- 调用 library/src/main/ets 下的主要功能文件，贯穿用户交互流程

### 3. entry/src/main/ets 部分核心文件

1. ChatItem.ets (viewmodel)

   - 存放单条对话数据结构，如消息内容、发送者身份
   - 与 AiDialogComponent.ets 结合，实现界面渲染

2. AiDialogComponent.ets (view)

   - 构建 AI 对话窗口，使用 Openai.ets 进行对话调用
   - 通过自定义弹窗控制器与主页面进行数据通信

3. MainPage.ets (pages)
   - 引用多处 view 及 viewmodel，用于管理账单数据、显示可视化图表
   - 同时集成 AI 对话功能，链接 AiDialogComponent.ets 并控制弹窗

### 4. PPT 演示要点 (补充)

- 可在演示时将各模块的调用顺序图、功能交互图与项目结构结合，突出以下要点：
  - 如何从 MainPage.ets 中调起对话框或调用库功能
  - 如何在 AiDialogComponent.ets 里完成用户输入与实时结果展示
  - 异步逻辑（AsyncCall.ets）的关键实现，在演示中可着重演示聊天数据流式返回
  - library/src/main/ets 下工具文件在对接外部服务时的重要作用

## 七、项目协作流程与关键注意事项

1. 项目分层

   - library：封装核心工具、对话功能、异步逻辑等
   - entry：负责业务逻辑实现及界面交互，搭配 library 的通用功能
   - database：持久化存储账单等数据，为 MainPage.ets、AiDialogComponent.ets 等提供数据支持

2. 协作流程概要

   - 功能拆分：前端界面(ArkTS)、后端工具模块及 AI 对接
   - 标准化接口：Openai.ets、ChatCompletion.ets 处理所有与 AI 相关的调用与响应，主页面只需调相关方法
   - 数据同步：通过 AccountTable.ets 进行数据库操作；AiDialogComponent.ets 完成对话与展示

3. 代码提交规范

   - 建议按照功能或模块提交，保持功能单元化
   - 避免在单次提交中包含多个无关改动
   - 每次提交前需自测，保证对话及数据模块都能正常运行

4. 例外与扩展

   - 可根据项目需求增加更多对话入口（如 ChatCompletion.ets 增加新方法）
   - 对数据库的扩展需先在 CommonConstants 中增加相应字段与 SQL 语句

5. 业务亮点与差异化

   - 将 AI 对话引入账单管理场景：提供财务分析与提示
   - 采用流式处理实现对话功能，减少等待时间
   - 接口设计具备可扩展性：多工具并行调用、丰富的回调管理

6. 流程图示（PPT 建议）

   - 绘制从 MainPage.ets 中调用 AiDialogComponent.ets，进而通过 Openai.ets 请求 ChatCompletion.ets 的流程图
   - 简要展示数据库存储与读取流程：AccountTable.ets 接口调用 → Rdb → 返回结果

7. 维护策略
   - 定期更新 Openai.ets 以及 ChatCompletion.ets，以兼容新的 AI 接口特性
   - 对 library 与 entry 的公共接口进行文档化，确保团队协同时易于查阅

## 八、项目背景与特色

- 背景：在财务管理场景中，传统工具常缺乏实时智能分析。本项目将账单管理与 AI 对话功能深度整合，避免单点应用带来的数据割裂。
- 特色：
  - 贴合 HarmonyOS 生态，使用 ArkTS 实现前后端一体化开发
  - 与 OpenAI 对话式交互无缝结合，为账单查询、统计和辅助决策提供实时反馈
  - 独立的库 (library) 模块搭配 entry 主业务逻辑，便于后续功能扩展与维护

## 九、使用场景举例

- 财务记录：用户在 MainPage.ets 中录入账户数据后，即可查看当月或全年支出与收入分布，直观掌握资金流向。
- 智能问答：通过 AiDialogComponent.ets 与 Openai.ets 的协同，用户可对话询问财务建议或快速分析近期支出。
- 统计可视化：ChatCompletion.ets 与 AsyncCall.ets 提供流式处理，搭配 McPieChart 和 McBarChart，实时绘制交互式图表，支持演示与报表场景。

## 十、技术要点

- HarmonyOS + ArkTS：简化多端布局，统一数据管理与组件开发。
- OpenAI 对接：使用 ChatCompletion 模型结构，实现多轮对话功能；AsyncCall.ets 负责异步回调的可靠实现。
- 高度模块化：library 内聚核心逻辑 (Function.ets、ChatCompletion.ets 等)，entry 通过解耦的方式调用，利于分工协作与后期维护。
- 数据库支持：AccountTable.ets 封装各种数据库操作 (增删改查)，保证账单数据与对话逻辑各司其职。

## 十一、未来发展方向

- 深化行业场景：进一步整合 ERP/CRM 功能，满足企业级财务管理需求。
- 优化自动化：在 ChatCompletion.ets 中扩展函数消息解析，实现更多半自动或自动化决策场景。
- 引入更多可自定义图表组件：满足更复杂的数据可视化需求，例如多维度交叉分析。
