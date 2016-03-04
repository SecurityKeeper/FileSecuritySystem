# FileSecuritySystem
## 系统架构介绍 
整个FileManager系统包含五个模块：Index Table(索引表)、Separator(分离器)、Stamper(压注器)、D/Encrytor(加解密器)、Archiver(归档器)。如图：
![image](https://github.com/SecurityKeeper/FileSecuritySystem/blob/master/ReadMe/system.png)
- **系统初始化变量**:  fileDirectory(文件存储文件夹)、systemKey(文件系统关键系数)、stamp(用户自定义标签)、加密系统可能用到的Key。
- **Index Table**：索引表是整个系统的关键，记录文件存储相关信息。其本身也是一个文件，其内部数据要经过压模－>加密－>归档，存储到fileDirectory中。
>1. 索引表的名称计算方法：用stamp(若不为int中，可按一定规则转换为int)对systemKey求余，得到的余数经过Base64编码即为存储的文件名。
>2. 索引表存储的信息：lastNode(一个记录目前系统自增数量的整数)、fileInfo(一个数组，包含所有文件的信息)。具体结构如下：
![image](https://github.com/SecurityKeeper/FileSecuritySystem/tree/master/ReadMe/index.png)
- **Separator**：分离器主要功能是将文件数据进行分片，便于后续分片加密存储。
>分片算法：如果文件DataLength<=systemKey，就不再分片，直接进行后续操作。如果Datalength>systemKey，首先用系统生成随机数random()与systemKey求余，余数remain作为分片数。然后DataLength/remain＝maxlength作为每片最大长度。最后，前remain-1片取random()%maxlength长数据，最后一片取剩余的数据。

- **stamper**：压注器主要是在分好的文件片后面再添加一段用户自定义的关键信息stamp，加强文件的保密性。
- **D/Encrytor**：数据加解密器，针对压注后的文件片进行加解密，目前系统使用的是AES加解密方式。（用户可自己选择这一块加解密方式）。
- **Archiver**：文件片归档器，将最后加密后的文件进行归档，存储到fileDirectory中。
>文件片名称计算方法：由索引表中记录的lastNode开始，每增加一片后lastNode＋1，记为当前文件地址数index，如果index<索引表存储位置数，这个index用Base64编码过后就是该片存储文件名，若index>=索引表存储位置数，该片文件名则为index+1经Base64编码后的值。

## 系统运行流程介绍
系统主要运行流程有三个：写入、读取、删除流程。
- **文件写入流程**：主要流程是将文件原数据分离，然后分别加注加密存储。具体流程如下：
``` flow
st=>start: 流程开始
op1=>operation: 读取索引表
cond1=>condition: 有无索引表
op2=>operation: 创建索引表
op3=>operation: 文件分片
op4=>operation: 片状文件加标记
op5=>operation: 片状文件加密
op6=>operation: 片状文件归档
op7=>operation: 更新索引表
e=>end: 流程结束

st->op1->cond1(no)->op2->op3
cond1(yes)->op3
op3->op4->op5->op6->op7->e
```
- **文件读取流程**：主要流程是根据索引表中片的位置，将所有片分别读取、解密、去标记、合并然后输出。具体流程如下：
``` flow
st=>start: 流程开始
op1=>operation: 读取索引表
cond1=>condition: 获取所有文件片
op2=>operation: 片状文件读取
op3=>operation: 片状文件解密
op4=>operation: 片状文件去标记
op5=>operation: 合并文件片
op6=>operation: 输出文档
e=>end: 流程结束

st->op1->cond1(yes)->op2->op3->op4->op5->op6->e
cond1(no)->e
```
- **文件删除流程**：主要流程是根据索引表，找到该文件的所有文件片，删除该文件的所有文件片，更新索引表。具体流程如下：
``` flow
st=>start: 流程开始
op1=>operation: 读取索引表
cond1=>condition: 有无索引表
cond2=>condition: 获取所有文件片
op2=>operation: 删除文件片
op3=>operation: 更新索引表
e=>end: 流程结束

st->op1->cond1(no)->e
cond1(yes)->cond2(no)->e
cond2(yes)->op2->op3->e
```
