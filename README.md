# Paradigm CTF 2023

[Paradigm CTF](https://ctf.paradigm.xyz/) 是区块链行业最顶级、知名度最高的针对智能合约黑客的在线竞赛，由 web3 顶级投资公司 Paradigm 组织，CTF 题目由 Sumczsun 和受到邀请的客座作者创造的多项挑战组成。每一项挑战的目标都是破解或通过攻击技术解决问题。

## 题目

- [x] Hello World(self-destruct)
- [ ] Black Sheep(Huff)
- [x] 100%(abi.encodePacket, 共享钱包的检查)
- [x] Dai++(clone 越界，未对敏感因子进行检查，绕过持仓检查)
- [x] DoDont(init 函数缺乏权限控制)
- [x] Grains of Sand
- [x] Suspicious Charity(变量类型不正确)
- [x] Token Locker (访问控制外部调用)
- [x] Skill Based Game(伪随机数)
- [x] Enterprise Blockchain(跨链触发机制，跨链消息触发无权限)
- [x] Dragon Tyrant(使用 codehash 来校验 implement，伪随机数，椭圆曲线)
- [x] Hopping Into Place(权限控制，借款无法更新, 项目方后门)
- [ ] Oven(web2-密码学)
- [ ] Dropper(随机数可以提前算出，地址可以预测，使用**huff**节省 gas)
- [X] Free Real Estate(目前实现的是通过存在的池子用较少token来获得router的空投(数量大))
- [X] Cosmic Radiation(理解加深操作码)
- [ ] Jotterp(Solana)

## 总结笔记

- 首先需要明确，不要一拿到合约就一头扎进去看，做 ctf 时需要明确夺旗目标，用目标出发去看合约。
- 明确项目类型和业务类型，多多关注非常规的入口条件，优先看外部调用的函数
- 找到影响因子之后，要从宏观上考虑什么会被影响因子左右
