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
        description: "Add new accounts",
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

    tools.push({
      function: {
        name: "update_account",
        description: "Update an account",
        parameters: {
          "type": "object",
          "properties": {
            "account": ({
              "type": "object",
              "properties": ({
                "id": ({
                  "type": "number",
                  "description": "The id of the account"
                } as ESObject),
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
          }
        }
      },
      type: "function"
    });


    tools.push({
      function: {
        name: "delete_account",
        description: `delete an account. Example usage: {\"account\": {\"id\": 6}}`,
        parameters: {
          "type": "object",
          "properties": {
            "account": ({
              "type": "object",
              "properties": ({
                "id": ({
                  "type": "number",
                  "description": "The id of the account"
                } as ESObject),
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


  callFunction(functionName: string, functionArguments: string, callback: (res: string) => void) {


    console.debug("Tool", "callFunction", functionName, functionArguments);


    switch (functionName) {
      case "get_current_time":
        callback(new Date().toLocaleString());
        return;
      case "add_account":

        // 尝试解析arguments，如果失败则返回失败信息
        try {

          // 截取字符串从[到]之间的内容,包括[和]
          functionArguments =
            functionArguments.substring(functionArguments.indexOf("["), functionArguments.lastIndexOf("]") + 1);

          let accountData: AccountData[] = JSON.parse(functionArguments);
          this.addAccount(accountData, callback);
          return;
        } catch (error) {
          callback("Failed to parse arguments");
          return
        }

      case "get_accounts":
        this.getAccounts(callback);
        return;

      case "update_account":
        try {

          let accountDataJson: Record<string, object> = JSON.parse(functionArguments);

          if (accountDataJson["account"] == undefined) {
            callback("Failed to parse arguments");
            return;
          }

          let accountData: AccountData = accountDataJson["account"] as AccountData;
          this.updateAccount(accountData, callback);
          return;
        } catch (error) {
          callback("Failed to parse arguments");
          return
        }

      case "delete_account":
        try {

          //`{"account":{"{"account":{"{"account":{"account": {"id": 44}}}`
          // 统计"{"的个数，并在最右边补充缺少的"}"，确保括号是匹配起来的
          while (functionArguments.split("{").length > functionArguments.split("}").length) {
            functionArguments += "}";
          }

          console.debug("Tool", "delete_account", functionArguments);

          let accountDataJson: Record<string, object> = JSON.parse(functionArguments);

          // 由于提供的 arguments 可能是 { "account": { "id": 6 } }，也可能是 { "account": { "account": { "id": 6 } } }，
          // 所以使用循环来获取到包含 id 属性的 account 对象
          // 使用 while 循环查找包含 id 属性的 account 对象
          let currentObj: Record<string, object>| undefined = accountDataJson;
          while (currentObj != undefined && typeof currentObj === 'object') {
            if (currentObj["id"] !== undefined) {
              break; // 找到包含 id 的对象，退出循环
            }

            if (currentObj["account"] !== undefined) {
              currentObj = currentObj["account"] as Record<string, object>; // 继续查找下一层
            } else {
              currentObj = undefined; // 没有找到 account 属性，终止循环
            }
          }

          let id = -1;
          if (currentObj == undefined || currentObj["id"] == undefined) {
            callback(`Failed to parse arguments, make sure the account object contains an id property. Example usage: {"account": {"id": 6}}`);
            return;
          }

          if(typeof currentObj["id"] != "number"){
            callback(`Failed to parse arguments, make sure the account object contains an id property. Example usage: {"account": {"id": 6}}`);
          }else{
            id = currentObj["id"] as number;
          }



          this.deleteAccount(id, callback);
          return;
        } catch (error) {
          callback("Failed to parse arguments");
          return
        }
    }

    callback("Function is not implemented");
  }



  /**
   * 添加账单
   * @param accounts 账单列表
   * @param callback
   */
  addAccount(accounts: AccountData[], callback: (res: string) => void) {

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


  /**
   * 获取全部账单信息
   * @param callback
   */
  getAccounts(callback: (result: string) => void) {

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


  /**
   * 在满足条件的情况下获取账单信息
   * @param account
   * @param callback
   */
  getAccountsByCondition(account: AccountData, callback: (result: string) => void) {

    let res = "empty";
    this.AccountTable.getRdbStore(() => {
      // 查询账户数据，从0开始，返回所有匹配的结果
      this.AccountTable.queryByCondition(account, (result: AccountData[]) => {
        console.debug("Tool", "getAccounts", JSON.stringify(result));
        res = JSON.stringify(result);
        callback(res);
      });
    });
  }


  /**
   * 更新账单信息
   * @param account 账单信息
   * @param callback 回调函数
   */
  updateAccount(account: AccountData, callback: (result: string) => void) {
    // 获取RDB存储，回调函数中将执行对数据库的操作
    this.AccountTable.getRdbStore(() => {

      this.AccountTable.queryByCondition(account, (queryRes: AccountData[]) => {

        if (queryRes.length == 0) {
          callback("Account not found");
          return;
        } else {
          this.AccountTable.updateData(account, (updateRes: boolean) => {
            if (updateRes) {
              callback("Updated successfully");
            } else {
              callback("Failed to update account");
            }
          })
        }
      })
    });
  }


  /**
   * 删除账单信息
   * @param id 账单ID
   * @param callback 回调函数
   */
  deleteAccount(id: number, callback: (result: string) => void) {
    // 获取RDB存储，回调函数中将执行对数据库的操作
    this.AccountTable.getRdbStore(() => {

      let account = new AccountData();
      account.id = id;

      this.AccountTable.queryByCondition(account, (queryRes: AccountData[]) => {

        if (queryRes.length == 0) {
          callback("Account not found");
          return;
        } else {
          this.AccountTable.deleteData(account, (deleteRes: boolean) => {
            if (deleteRes) {
              callback("Deleted successfully");
            } else {
              callback("Failed to delete account");
            }
          })
        }
      })
    });
  }
}
