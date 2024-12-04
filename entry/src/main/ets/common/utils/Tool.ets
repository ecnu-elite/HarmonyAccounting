import { ChatCompletionToolParam } from '@adrian_wang/openai/src/main/ets/Function';
import AccountData from '../../viewmodel/AccountData';
import { PayList,EarnList } from '../../viewmodel/AccountList';
import AccountTable from '../database/tables/AccountTable';


export class Tool{


  private AccountTable = new AccountTable(() => {});


  // 获取账单类型的枚举值类型
  private accountType:Map<string, number> = new Map<string, number>();

  constructor() {
    this.getAccountType();
  }

  getAccountType(){

    for(let payList of PayList){
      this.accountType.set(payList.typeText, payList.accountType);
    }

    for(let earnList of EarnList){
      this.accountType.set(earnList.typeText, earnList.accountType);
    }
  }


  /**
   * 获取工具列表
   * @returns 工具列表
   */
   getTools(): Iterable<ChatCompletionToolParam> | undefined {
    let tools: ChatCompletionToolParam[] = []



    let parameters: Map<string, object>;



    /*TODO*******************************************************************
     *                     这里添加函数清单                                    *
     *TODO*******************************************************************/
    parameters = new Map<string, object>();
    let time_format = new Map<string, object>();

    time_format["type"] = "string"
    time_format["description"] = "The format of the time"

    parameters["type"] = "object"
    parameters["properties"] = {
      "time_format": time_format
    }

    tools.push({
      function:{
        name: "get_current_time",
        description: "Get the current time",
        parameters:parameters
      },
      type: "function"
    })
    let account_parameters = new Map<string, object>();
    let account_properties = new Map<string, object>();


    account_properties["accountType"] = {
      "type": "number",
      "enum":  Array.from(this.accountType.values()),
      "description": "The accountTypeId of the account"
    };
    account_properties["typeText"] = {
      "type": "string",
      "enum":  Array.from(this.accountType.keys()),
      "description": "The name of type of the account"
    };
    account_properties["amount"] = {
      "type": "number",
      "description": "The amount of the account"
    };
    account_properties["time"] = {
      "type": "string",
      "description": "The time of the account,example:`2024-12-4 星期三`"
    };

    let items: Map<string, object> = new Map<string, object>();

    items["type"] = "object";
    items["properties"] = account_properties;

    let accounts = new Map<string, object>();

    accounts["type"] = "array";
    accounts["items"] = items;

    account_parameters["type"] = "object";
    account_parameters["properties"] = {
      "accounts": accounts
    };

    tools.push({
      function: {
        name: "add_account",
        description: "Add a new account",
        parameters: account_parameters
      },
      type: "function"
    });

    /***********************************************************************/

    return tools;
  }


  callFunction(functionName:string, functionArguments:string):string {


    console.debug("Tool", "callFunction", functionName, functionArguments);


    switch (functionName) {
      case "get_current_time":
        return new Date().toLocaleTimeString();
      case "add_account":

        // 尝试解析arguments，如果失败则返回失败信息
        try {

          // 截取字符串从[到]之间的内容,包括[和]
          functionArguments = functionArguments.substring(functionArguments.indexOf("["),functionArguments.lastIndexOf("]")+1);


          let accountData: AccountData[] = JSON.parse(functionArguments);
          this.addAccount(accountData);

        } catch (error) {
          return "Failed to parse arguments";
        }

        return "Account added successfully";
    }

    return "Function is not implemented";
  }

  //TODO TEST

  addAccount(accounts: AccountData[]): string {

    let res = "Account added successfully";

    // 获取RDB存储，回调函数中将执行对数据库的操作
    this.AccountTable.getRdbStore(()=>{
      try {
        for (let account of accounts) {
          console.debug("Tool", "addAccount", JSON.stringify(account));
          account.id = 0;
          this.AccountTable.insertData(account,(id: number)=>{
            console.log("Account add ID:",id);
          })
        }
      } catch (error) {
        console.error("Tool", "addAccount", error);
        res = "Failed to add account";
      }
    });



    return res;


  }


}
