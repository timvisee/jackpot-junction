# The store page in Simplified Chinese

The Simplified Chinese for everything [STEAM.md](../STEAM.md) has the store page say in words,
"Words for the store page" and the supporter pack's "Words for its store page", in the game's own
terms ([TRANSLATING.md](../TRANSLATING.md), Simplified Chinese): 庄家 for the House, 筹码 for chips,
彩池 for the pot, 兑现 for cashing out, 小丑牌 for jokers, 道具 for power-ups, 路口 for the Junction.
The game itself is 头奖路口, the Jackpot and the Junction word for word, as most games put into
Chinese have a Chinese name on Steam; 头奖路口（Jackpot Junction） where a page first names it.
Steam shows each visitor the page in the language their Steam is in, and English where a part has
none, so the English stays as it is. When the English changes, this changes with it.

These words are a draft for a native speaker to read over, as the game's own Chinese is.

Everything the game hands Steam itself, the friends list's words, the achievements and the
controller actions, comes from the game's translations, see STEAM.md.

## Putting it up

1. **The name**: under the game's General Application Settings (Steamworks Settings), Localized
   Application Names, Simplified Chinese: `头奖路口`, and publish the Steamworks settings. Chinese
   visitors see it on the store page and in their library, and Steam's search finds the game by
   either name. The capsules keep the English wordmark.
2. **Supported languages** (Edit Store Page > Basic Info): add Simplified Chinese with Interface
   ticked, not Full Audio, not Subtitles, as nothing is voiced.
3. **The words** (Edit Store Page, each tab with words): pick Simplified Chinese in the language
   menu at the top and fill in the fields below, then save. A field left empty in Simplified
   Chinese shows the English.
4. **The description's pictures**: `make steam-art` draws the ones with words in them in Simplified
   Chinese, into `build/steam-art/description/schinese/` and `docs/description/schinese/`, each
   named for the language, `heading_your_ride_schinese.png`, so it goes up beside the English
   instead of over it. With the Simplified Chinese description open, upload them with the editor's
   image button as the English ones were. The karts have no words: the Chinese description shows
   the English picture.
5. **The screenshots**: `make steam-art` also takes them in Simplified Chinese, into
   `build/steam-art/screenshots/schinese/`, `01-teams-close-up_schinese.png` and on. On the
   screenshots page, drag each onto the thumbnail of the English one with its number: Steam keeps it
   as that screenshot's Simplified Chinese version, which the `_schinese` in its name tells it. Mark
   each suitable for all ages, as the English ones are. Take them once the game's own Chinese is
   done, or they show its English.
6. **The trailer**, if wanted: `make trailer LANGUAGE=zh_CN` records it in Simplified Chinese into
   `build/trailer/schinese/`, see STEAM.md "The trailer". Upload `jackpot-junction-trailer.mp4`
   from there as a trailer of its own and set its language to Simplified Chinese, so Chinese
   visitors see it in place of the English one.
7. Publish the store page. The capsules and the library's art have no words but the game's name,
   which stays, and Steam has no Chinese version of them.

## Short description

> 俯视角卡丁车竞技场，每一条命都是一手牌。捞起扑克筹码，撞飞其他卡丁车，用小丑牌改写规则，抢在被人收拾之前开到路口兑现。同屏最多四人，联机最多八人。

## About This Game

The pictures, with their alt text in the Description tab:

| Picture | Alt text |
|---|---|
| `heading_how_the_cards_roll_schinese.png` | 牌局怎么走 |
| `heading_whats_in_the_deck_schinese.png` | 想知道牌组里有什么？ |
| `picture_jokers_schinese.png` | 一手五张小丑牌：灌铅骰子、弧线球、扒手、守护天使和百搭牌 |
| `picture_power_ups_schinese.png` | 一手五张道具牌：火箭、护盾、炸弹、炮塔和诱饵卡丁车 |
| `heading_never_play_alone_schinese.png` | 打牌从不孤单。真的吗？ |
| `heading_your_ride_schinese.png` | 你的车，你做主 |
| `picture_karts.png`, the English one | 五辆卡丁车排成一行，各有自己的车身、涂装和帽子 |

```text
[b]有人说要来点混乱？[/b]漂移、躲子弹、疯狂捞扑克筹码，好像下个月的房租全指望它了，同时还得当心别成了路边的一摊。考个驾照，跳上你改装好的卡丁车，向最多七位朋友发起挑战，看谁能捞到最大的一笔。兑现之前就挂了？那就血本无归。简单吧？嗯，祝你好运。

[img]{STEAM_APP_IMAGE}/extras/heading_how_the_cards_roll_schinese.png[/img]
[list]
[*][b]收集[/b]筹码：筹码垫上的、木箱里的、头奖里的，还有你撞出局的卡丁车掉下的。每一枚都进你的彩池。
[*][b]翻倍[/b]：干掉其他卡丁车。你的彩池值多少，就是筹码乘以倍率。
[*][b]改写规则[/b]：用能扭转局面的小丑牌。倒下时可能走运，也可能被诅咒……谁知道呢。
[*][b]兑现[/b]：把卡丁车开上路口。半路挂掉，辛苦全白费。
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_whats_in_the_deck_schinese.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_jokers_schinese.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_power_ups_schinese.png[/img]
[list]
[*]赌桌就是你的竞技场。绕着障碍漂移，掉进坑洞，收集扑克筹码赢下比赛。
[*]48 张小丑牌。弧线球、会漂移的筹码、会反弹的子弹、顺手牵羊，应有尽有。其中 27 张由庄家请客，其余的在路上赢回来。
[*]21 种道具。护盾、炸弹、炮塔、诱饵、油渍等等，拼了命地去搅和朋友的卡丁车（真的是拼命）。
[*]一分钟一局，或者来个全套：有快速比赛，也有横跨多张地图的大奖赛。每辆卡丁车各自为战，或者组队共拿一个分数。
[*]专属于你的卡丁车。从鲨鱼鳍帽子到彩纸拖尾，再到印着你名字的车牌。
[*]忠诚自有回报。你那张押满赌注的路线图，会换来卡丁车装扮，或者给你的小丑牌组添新牌。
[*]新来的？我们带你转转。到驾校考个驾照，再去车库练练漂移。
[*]一路上还有一段故事，让你的卡丁车和牌组越来越顺手。嫌它碍事，随时可以关掉。
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_never_play_alone_schinese.png[/img]
[list]
[*][b]只有一块屏幕？[/b]最多和四位朋友一起上路，谁想加入随时加入。没错，比赛中途也行。
[*][b]要开局域网？[/b]自己开一局，按你的方式邀请朋友。
[*][b]想在线玩？[/b]在专用服务器上开一局，或者加入现有的对局，和最多八位不要命的车手同场。
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_your_ride_schinese.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_karts.png[/img]
不管你是看不惯场边那群迪斯科观众，还是正和那位离不开辅助瞄准的朋友一起玩：游戏都能按你的需要来调整。

头奖路口（Jackpot Junction）是开源游戏，采用 GPL-3.0 许可，使用 Godot 制作。游戏自有的美术采用 CC BY 4.0 许可。
```

## System requirements

The additional notes, where Steamworks takes them per language; the rest of the table is the
English, with numbers and names that need no translating.

> 只有在线游戏需要联网；单人对战机器人、本地多人和局域网对局都可以离线进行。最多 4 名玩家用手柄同屏游戏，在线最多 8 人。使用集成显卡时，请在设置中调低渲染比例和阴影。

## Content and legal

Where Steamworks takes them per language.

- **AI disclosure**: "本游戏由生成式 AI 制作，人类提供了一些协助。AI 编写了代码和游戏内的文字，美术由这些代码绘制，因此没有使用任何图像、语音或音乐生成工具。音乐、音效和字体均由人类创作。"
- **Legal notice**: "头奖路口（Jackpot Junction）是自由软件，采用 GPL-3.0 许可，并附有链接 Steamworks SDK 的额外许可。游戏自有的美术采用 CC BY 4.0 许可。音乐由 Ovani Sound 创作，授权给本游戏的开发者使用。第三方素材列于游戏的制作人员名单中。"

## The supporter pack

The DLC's own store page, in its own Edit Store Page, as the game's above: Simplified Chinese under
Supported languages, the words below with Simplified Chinese picked, its two headings from
`docs/description/supporter/schinese/` and its three screenshots from
`build/steam-art/supporter/screenshots/schinese/`, each dragged onto its English one.

**Its name**: under the DLC's General Application Settings (Steamworks Settings), Localized
Application Names, Simplified Chinese: `头奖路口 - 支持者礼包`, which the game's own
Chinese for the Supporter Pack should match.

Short description:

> 为一款免费游戏送上的一点小小谢意。十一件会发光、会旋转、会随彩池变化的卡丁车装扮，三种牌背，还有车牌上的一颗星。没有任何能帮你赢下比赛的东西：只是表明你出过一份力。

The pictures, with their alt text:

| Picture | Alt text |
|---|---|
| `heading_supporter_thanks_schinese.png` | 穿在身上的谢意 |
| `picture_supporter_karts.png`, the English one | 五辆卡丁车，戴着纸牌屋、招财猫、扫着光束的灯塔、光环和小费罐，挂着灯笼和风车，刷着夜空涂装 |
| `heading_supporter_pieces_schinese.png` | 礼包内容一览 |
| `picture_supporter_backs.png`, the English one | 一手三张牌，牌背分别是灯标、星座和极光 |

About This Content:

```text
头奖路口是免费的，并且会一直免费。支持者礼包是为那些想回馈一点、也想在牌桌上亮出来的人准备的。

[img]{STEAM_APP_IMAGE}/extras/heading_supporter_thanks_schinese.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_supporter_karts.png[/img]
每一件都会发光、旋转或随你的彩池变化，让整张牌桌都看得到是谁出了力。纸牌屋随你的彩池越搭越高，你一倒下它就塌；招财猫在你捡到筹码后招手招得更快；灯塔的光束扫过整片绒布桌面。

[img]{STEAM_APP_IMAGE}/extras/heading_supporter_pieces_schinese.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_supporter_backs.png[/img]
[list]
[*][b]灯塔[/b]（帽子）：灯头旋转，一道柔和的光束扫过绒布桌面。
[*][b]光环[/b]（帽子）：头盔上方一圈温暖的光。
[*][b]纸牌屋[/b]（帽子）：彩池越多，楼层越高；开起车来摇摇晃晃，你一倒下它也跟着塌。
[*][b]招财猫[/b]（帽子）：一直在招手，捡到筹码后招得更快，兑现时还会欢呼。
[*][b]小费罐[/b]（帽子）：彩池越多，罐里的筹码越满。
[*][b]灯笼[/b]（旗子）：一盏以你的颜色发光的纸灯笼。
[*][b]风车[/b]（旗子）：随你的车速转动。
[*][b]棱镜[/b]（拖尾）：一条光带，漂移时留下彩虹般的弧线。
[*][b]星尘[/b]（拖尾）：闪烁的光点停留在你经过的地方。
[*][b]夜空[/b]（涂装）：把你的颜色变成繁星满天的夜空。
[*][b]星光[/b]（饰面）：飘浮的星星，可以配在你穿戴的任何一件上。
[*][b]灯标[/b]、[b]星座[/b]和[b]极光[/b]（牌背），装点你的小丑牌组。
[*]车牌上的[b]一颗星[/b]，以及驾照上的一条[b]支持者[/b]签注。
[/list]

里面的一切都只为好看。它不会改变比赛怎么玩、怎么赢，每一张小丑牌、每一种道具和每一张赌桌对所有人都免费。
```
