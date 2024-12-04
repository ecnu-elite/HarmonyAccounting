import { ChatCompletionToolParam } from '@adrian_wang/openai/src/main/ets/Function';
import AccountData from '../../viewmodel/AccountData';
import { PayList, EarnList } from '../../viewmodel/AccountList';
import AccountTable from '../database/tables/AccountTable';
import call from '@ohos.telephony.call';


export class Tool {
  private AccountTable = new AccountTable(() => {
  });
  // 获取账单类型的枚举值类型
  private accountType: Map<string, number> = new Map<string, number>();

  constructor() {
    this.getAccountType();
  }

  getAccountType() {

    for (let payList of PayList) {
      this.accountType.set(payList.typeText, payList.accountType);
    }

    for (let earnList of EarnList) {
      this.accountType.set(earnList.typeText, earnList.accountType);
    }
  }


  /**
   * 获取工具列表
   * @returns 工具列表
   */
  getTools(): Iterable<ChatCompletionToolParam> | undefined {
    let tools: ChatCompletionToolParam[] = []

    /*TODO*******************************************************************
     *                     这里添加函数清单                                    *
     *TODO*******************************************************************/


    tools.push({
      function: {
        name: "get_current_time",
        description: "Get the current time",
        parameters: {
          "type": "object",
          "properties": {
            "time_format": ({
              "type": "string",
              "description": "The format of the time"
            } as ESObject)
          }
        }
      },
      type: "function"
    })

    tools.push({
      function: {
        name: "get_accounts",
        description: "get all accounts",
        parameters: {
          "type": "object",
          "properties": {}
        }
      },
      type: "function"
    })


    tools.push({
      function: {
        name: "add_account",
        description: "Add a new account",
        parameters: {
          "type": "object",
          "properties": {
            "accounts": ({
              "type": "array",
              "items": ({
                "type": "object",
                "properties": ({
                  "accountType": ({
                    "type": "number",
                    "enum": Array.from(this.accountType.values()),
                    "description": "The accountTypeId of the account"
                  } as ESObject),
                  "typeText": ({
                    "type": "string",
                    "enum": Array.from(this.accountType.keys()),
                    "description": "The name of type of the account"
                  } as ESObject),
                  "amount": ({
                    "type": "number",
                    "description": "The amount of the account"
                  } as ESObject),
                  "time": ({
                    "type": "string",
                    "description": "The time of the account,example:`2024-12-4 星期三`"
                  } as ESObject)
                } as ESObject)
              } as ESObject)
            } as ESObject)
          }
        }
      },
      type: "function"
    });

    /***********************************************************************/

    return tools;
  }


  callFunction(functionName: string, functionArguments: string,callback: (res:string)=>void) {


    console.debug("Tool", "callFunction", functionName, functionArguments);


    switch (functionName) {
      case "get_current_time":
        callback(new Date().toLocaleTimeString());
        return;
      case "add_account":

        // 尝试解析arguments，如果失败则返回失败信息
        try {

          // 截取字符串从[到]之间的内容,包括[和]
          functionArguments =
            functionArguments.substring(functionArguments.indexOf("["), functionArguments.lastIndexOf("]") + 1);

          let accountData: AccountData[] = JSON.parse(functionArguments);
          this.addAccount(accountData,callback);
          return;
        } catch (error) {
          callback("Failed to parse arguments");
          return
        }

      case "get_accounts":
        this.getAccounts(callback);
        return;
    }

    callback("Function is not implemented");
  }


  addAccount(accounts: AccountData[],callback: (res:string)=>void) {

    let res = "Account added successfully";

    // 获取RDB存储，回调函数中将执行对数据库的操作
    this.AccountTable.getRdbStore(() => {
      try {
        for (let account of accounts) {
          console.debug("Tool", "addAccount", JSON.stringify(account));
          account.id = 0;
          this.AccountTable.insertData(account, (id: number) => {
            console.log("Account add ID:", id);
          })
        }
      } catch (error) {
        console.error("Tool", "addAccount", error);
        res = "Failed to add account";
      }
      callback(res);
    });


  }



  getAccounts(callback:(result:string)=>void){

    let res = "empty";
    this.AccountTable.getRdbStore(() => {
      // 查询账户数据，从0开始，返回所有匹配的结果
      this.AccountTable.query(0, (result: AccountData[]) => {
        console.debug("Tool", "getAccounts", JSON.stringify(result));
        res = JSON.stringify(result);
        callback(res);
      }, true);
    });

  }


}
