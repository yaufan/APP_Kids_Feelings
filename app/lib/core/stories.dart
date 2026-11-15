import 'feelings.dart';

/// Who a cloud in a picture is (all drawn by the app from [Look]s).
enum CloudKind {
  /// 棉棉: a curl of cloud on top.
  mianmian,

  /// 小雨, the friend: a little water drop on top.
  xiaoyu,

  /// A grown-up: a bigger, calm cloud (parents, the teacher, 阿嬤, the doctor).
  grownup,

  /// Another child.
  pal,

  /// A little brother: small.
  baby,
}

/// Where a story happens: a background picture (assets/art/stories/bg_<name>.svg).
enum StoryPlace { home, school, park, night, clinic, market, rain }

/// A picture on top of the background: assets/art/stories/<art>.svg, its
/// middle at [x] and its bottom at [y] (fractions of the 4:3 picture), [w]
/// wide (a fraction of the picture's width).
class Prop {
  const Prop(this.art, this.x, this.y, this.w);

  final String art;
  final double x, y, w;
}

/// Another cloud in the picture, with its bottom at [y].
class Cast {
  const Cast(this.kind, this.x, this.y, this.w, {this.tint, this.feeling, this.flip = false});

  final CloudKind kind;
  final double x, y, w;

  /// Its colour (a grown-up or a friend keeps its own colour whatever it feels).
  final int? tint;

  /// Its face (null: calm).
  final Feeling? feeling;
  final bool flip;
}

/// A card for the grown-up (docs/design.md 「家長一起說」).
class TalkCard {
  const TalkCard({required this.ask, required this.say, required this.tip});

  /// 問問孩子.
  final String ask;

  /// 可以一起說.
  final String say;

  /// 小提醒.
  final String tip;
}

/// A little story: one picture and one sentence, then 「小雨現在是什麼心情？」.
class Story {
  const Story({
    required this.id,
    required this.title,
    required this.line,
    required this.place,
    required this.right,
    required this.small,
    required this.card,
    this.props = const [],
    this.cast = const [],
    this.xiaoyu = const (0.5, 0.86, 0.3),
  });

  final String id;

  /// The story's name, for grown-ups (parent mode).
  final String title;

  /// What happened (read out).
  final String line;
  final StoryPlace place;

  /// The feelings that count as right at 大 (one to three; docs/design.md:
  /// 好幾個答案都對). The first is the one 小雨 shows in 怎麼辦.
  final List<Feeling> right;

  /// The right ones at 小小: basic feelings only; empty means the story is
  /// only told at 大.
  final List<Feeling> small;
  final TalkCard card;
  final List<Prop> props;
  final List<Cast> cast;

  /// Where 小雨 stands: middle x, bottom y, width (fractions).
  final (double, double, double) xiaoyu;

  /// The right feelings at [level].
  List<Feeling> rightAt(Level level) => level == Level.small ? small : right;

  /// What 小雨 feels in the story.
  Feeling get main => right.first;

  /// A good thing happened: the friend is cheered, not comforted.
  bool get pleasant => main.pleasant;
}

/// What a child can do for a friend (怎麼辦). All of them are good ones.
enum HelpWay {
  hug('抱抱小雨', '棉棉抱抱小雨，小雨覺得好多了。', 'hug'),
  ask('問：你還好嗎？', '「你還好嗎？」小雨說：「謝謝你問我。」', 'chime'),
  adult('去找大人', '大人來了，牽著小雨的手。小雨安心了。', 'steps'),
  clap('一起拍拍手', '拍拍手！小雨更開心了。', 'clap'),
  praise('說：好棒喔！', '「好棒喔！」小雨笑得好開心。', 'sparkle'),
  share('給小雨抱抱', '抱一個！開心的事，一起開心。', 'hug');

  const HelpWay(this.zh, this.result, this.sound);

  final String zh;

  /// What happens (read out).
  final String result;
  final String sound;

  static const comfort = [hug, ask, adult];
  static const cheer = [clap, praise, share];
}

/// The stories (docs/design.md 「小故事」): everyday things at home and at
/// kindergarten in Taiwan, gentle, nothing scary.
const stories = <Story>[
  Story(
    id: 'toy_broken',
    title: '玩具壞掉了',
    line: '小雨最喜歡的小車車，壞掉了。',
    place: StoryPlace.home,
    right: [Feeling.sad, Feeling.angry, Feeling.disappointed],
    small: [Feeling.sad, Feeling.angry],
    props: [Prop('car_broken', .74, .9, .26)],
    xiaoyu: (.4, .88, .3),
    card: TalkCard(
      ask: '你有沒有東西壞掉的時候？那時候你是什麼心情？',
      say: '東西壞掉會難過，也會生氣。難過的時候可以說出來、可以抱抱，或是請大人幫忙。',
      tip: '先聽孩子說，不用急著教。',
    ),
  ),
  Story(
    id: 'friend_left',
    title: '好朋友先回家了',
    line: '好朋友先回家了，只剩小雨一個人。',
    place: StoryPlace.school,
    right: [Feeling.sad, Feeling.disappointed],
    small: [Feeling.sad],
    cast: [Cast(CloudKind.pal, .86, .74, .16, tint: 0xFFF9C6D6, feeling: Feeling.happy, flip: true), Cast(CloudKind.grownup, .95, .78, .2, tint: 0xFFFFDDBE)],
    xiaoyu: (.38, .9, .3),
    card: TalkCard(
      ask: '好朋友先走了，你會怎麼樣？',
      say: '朋友走了會捨不得、會難過。明天還可以再一起玩。',
      tip: '可以一起想「明天要跟他玩什麼」。',
    ),
  ),
  Story(
    id: 'dark_room',
    title: '房間暗暗的',
    line: '晚上關燈了，房間暗暗的，窗外有聲音。',
    place: StoryPlace.night,
    right: [Feeling.scared, Feeling.nervous],
    small: [Feeling.scared],
    xiaoyu: (.5, .9, .3),
    card: TalkCard(
      ask: '晚上暗暗的時候，你會怕嗎？',
      say: '暗暗的會害怕，很多人都會。可以抱著小被被，也可以叫爸爸媽媽。',
      tip: '不用說「這有什麼好怕的」，先說「我知道你會怕」。',
    ),
  ),
  Story(
    id: 'praised',
    title: '被老師稱讚',
    line: '老師說：「小雨把積木收得好整齊！」',
    place: StoryPlace.school,
    right: [Feeling.happy, Feeling.proud, Feeling.shy],
    small: [Feeling.happy],
    props: [Prop('blocks', .78, .9, .2)],
    cast: [Cast(CloudKind.grownup, .2, .82, .26, tint: 0xFFE2D6F7, feeling: Feeling.happy)],
    xiaoyu: (.52, .9, .28),
    card: TalkCard(
      ask: '被稱讚的時候，你心裡覺得怎麼樣？',
      say: '被稱讚會開心，也會有一點得意、有一點害羞，都可以。',
      tip: '稱讚做的事：「你收得好整齊」，比「你好棒」更清楚。',
    ),
  ),
  Story(
    id: 'long_line',
    title: '排隊等很久',
    line: '排隊等溜滑梯，等了好久好久。',
    place: StoryPlace.park,
    right: [Feeling.bored, Feeling.angry],
    small: [Feeling.angry],
    props: [Prop('slide', .8, .9, .34)],
    cast: [Cast(CloudKind.pal, .58, .88, .16, tint: 0xFFFFD8B0), Cast(CloudKind.pal, .4, .88, .16, tint: 0xFFF9C6D6)],
    xiaoyu: (.18, .9, .22),
    card: TalkCard(
      ask: '要等很久的時候，你會怎麼樣？',
      say: '等很久會無聊，也會不耐煩。可以一邊等一邊數數、唱歌。',
      tip: '等待是可以練的：先從很短的等開始。',
    ),
  ),
  Story(
    id: 'grandma',
    title: '阿嬤來了',
    line: '叮咚！阿嬤來看小雨了。',
    place: StoryPlace.home,
    right: [Feeling.happy, Feeling.surprised],
    small: [Feeling.happy],
    props: [Prop('door_open', .82, .86, .24)],
    cast: [Cast(CloudKind.grownup, .78, .88, .28, tint: 0xFFEADDF0, feeling: Feeling.happy, flip: true)],
    xiaoyu: (.36, .9, .3),
    card: TalkCard(
      ask: '誰來看你的時候，你會很開心？',
      say: '喜歡的人來了會好開心，還會想要抱抱。',
      tip: '可以一起打電話或視訊給阿公阿嬤，說說今天的事。',
    ),
  ),
  Story(
    id: 'milk',
    title: '弄倒牛奶',
    line: '小雨不小心把牛奶弄倒了。',
    place: StoryPlace.home,
    right: [Feeling.surprised, Feeling.sad, Feeling.nervous],
    small: [Feeling.sad],
    props: [Prop('table', .64, .92, .4), Prop('milk', .66, .6, .24)],
    xiaoyu: (.26, .9, .28),
    card: TalkCard(
      ask: '你弄倒東西的時候，心裡是什麼感覺？',
      say: '不小心的事，每個人都會有。擦一擦就好了，可以說「我來幫忙擦」。',
      tip: '把重點放在「怎麼收拾」，不是「怎麼又弄倒」。',
    ),
  ),
  Story(
    id: 'first_day',
    title: '第一天上學',
    line: '今天是小雨第一天上幼兒園。',
    place: StoryPlace.school,
    right: [Feeling.nervous, Feeling.scared, Feeling.shy],
    small: [Feeling.scared],
    props: [Prop('backpack', .22, .9, .16)],
    cast: [Cast(CloudKind.grownup, .8, .84, .26, tint: 0xFFE2D6F7, feeling: Feeling.happy, flip: true)],
    xiaoyu: (.46, .9, .28),
    card: TalkCard(
      ask: '第一次去一個新地方，你會緊張嗎？',
      say: '新的地方會緊張、會怕，慢慢就會認識新朋友。',
      tip: '可以先說好「放學時誰來接你」，孩子會比較安心。',
    ),
  ),
  Story(
    id: 'shot',
    title: '要打針',
    line: '醫生說：「要打一針喔。」',
    place: StoryPlace.clinic,
    right: [Feeling.scared, Feeling.nervous],
    small: [Feeling.scared],
    props: [Prop('bandage', .62, .5, .12)],
    cast: [Cast(CloudKind.grownup, .78, .86, .28, tint: 0xFFD6EEF7, feeling: Feeling.calm, flip: true)],
    xiaoyu: (.36, .9, .28),
    card: TalkCard(
      ask: '打針之前，你的心情是什麼？',
      say: '打針會怕、會緊張。可以握著大人的手，深呼吸，一下就好了。',
      tip: '誠實說「會有一點痛，一下下」，比說「不會痛」好。',
    ),
  ),
  Story(
    id: 'gift',
    title: '生日收到禮物',
    line: '生日到了，小雨收到一個禮物！',
    place: StoryPlace.home,
    right: [Feeling.happy, Feeling.surprised],
    small: [Feeling.happy],
    props: [Prop('cake', .78, .9, .22), Prop('gift', .6, .9, .16)],
    xiaoyu: (.32, .9, .3),
    card: TalkCard(
      ask: '收到禮物的時候，你會怎麼樣？',
      say: '收到禮物好開心！可以跟送禮物的人說「謝謝你」。',
      tip: '開心也是心情：說出「你看起來好開心」也很好。',
    ),
  ),
  Story(
    id: 'car_taken',
    title: '別人拿走我的車',
    line: '小雨在玩車車，別人一把拿走了。',
    place: StoryPlace.school,
    right: [Feeling.angry, Feeling.sad],
    small: [Feeling.angry, Feeling.sad],
    props: [Prop('car', .8, .78, .16)],
    cast: [Cast(CloudKind.pal, .8, .9, .2, tint: 0xFFFFD8B0, feeling: Feeling.happy, flip: true)],
    xiaoyu: (.36, .9, .3),
    card: TalkCard(
      ask: '別人拿走你的東西，你會怎麼樣？',
      say: '東西被拿走會生氣。可以說「我還在玩」，或是去找大人，不要打人。',
      tip: '先接住生氣：「你很生氣，因為你還在玩。」',
    ),
  ),
  Story(
    id: 'lost_mom',
    title: '找不到媽媽',
    line: '在超市裡，一轉頭，找不到媽媽了。',
    place: StoryPlace.market,
    right: [Feeling.scared, Feeling.nervous],
    small: [Feeling.scared],
    props: [Prop('cart', .8, .9, .22)],
    xiaoyu: (.42, .9, .28),
    card: TalkCard(
      ask: '如果找不到爸爸媽媽，你會怎麼做？',
      say: '找不到大人會很害怕。站在原地，請店員或穿制服的人幫忙找。',
      tip: '可以和孩子練習說出自己的名字和爸媽的名字。',
    ),
  ),
  Story(
    id: 'high_slide',
    title: '溜滑梯好高',
    line: '溜滑梯好高好高，小雨站在最上面。',
    place: StoryPlace.park,
    right: [Feeling.scared, Feeling.nervous],
    small: [Feeling.scared],
    props: [Prop('slide', .5, .92, .56)],
    xiaoyu: (.36, .34, .2),
    card: TalkCard(
      ask: '你有沒有覺得「好高喔」的時候？',
      say: '高高的會怕，可以慢慢來，也可以下次再試試看。',
      tip: '不用推孩子「快溜啊」，讓他自己決定。',
    ),
  ),
  Story(
    id: 'left_out',
    title: '同學不跟我玩',
    line: '小雨想一起玩，可是同學說：「不要。」',
    place: StoryPlace.school,
    right: [Feeling.sad, Feeling.angry, Feeling.disappointed],
    small: [Feeling.sad, Feeling.angry],
    props: [Prop('blocks', .76, .9, .18)],
    cast: [Cast(CloudKind.pal, .76, .74, .16, tint: 0xFFF9C6D6, feeling: Feeling.bored, flip: true)],
    xiaoyu: (.34, .9, .3),
    card: TalkCard(
      ask: '有人不跟你玩的時候，你心裡會怎麼樣？',
      say: '別人說不要，會難過、會生氣。可以去找別的朋友，或是等一下再問一次。',
      tip: '可以一起想：還有誰也喜歡玩一樣的東西？',
    ),
  ),
  Story(
    id: 'drawing',
    title: '畫被貼在牆上',
    line: '小雨畫的圖，被老師貼在牆上了！',
    place: StoryPlace.school,
    right: [Feeling.proud, Feeling.happy, Feeling.shy],
    small: [Feeling.happy],
    props: [Prop('drawing', .7, .5, .22)],
    xiaoyu: (.36, .9, .3),
    card: TalkCard(
      ask: '你做了什麼事，讓自己覺得很得意？',
      say: '做到一件事會得意，覺得「我好厲害」，這是很棒的感覺。',
      tip: '問問孩子「你最喜歡哪一個部分？」，讓他說自己的作品。',
    ),
  ),
  Story(
    id: 'new_toy',
    title: '弟弟有新玩具',
    line: '弟弟拿到新玩具，小雨沒有。',
    place: StoryPlace.home,
    right: [Feeling.jealous, Feeling.sad, Feeling.angry],
    small: [Feeling.sad, Feeling.angry],
    props: [Prop('robot', .66, .82, .1)],
    cast: [Cast(CloudKind.baby, .74, .9, .16, tint: 0xFFFFE6A8, feeling: Feeling.happy, flip: true)],
    xiaoyu: (.34, .9, .3),
    card: TalkCard(
      ask: '別人有、你沒有的時候，你會怎麼樣？',
      say: '別人有、自己沒有，會嫉妒、會難過，這種感覺很正常。',
      tip: '說出來就好：「你也很想要，對不對？」不用馬上解決。',
    ),
  ),
  Story(
    id: 'rainy',
    title: '下雨不能出去玩',
    line: '下雨了，不能去公園玩。',
    place: StoryPlace.rain,
    right: [Feeling.bored, Feeling.disappointed, Feeling.sad],
    small: [Feeling.sad],
    xiaoyu: (.5, .9, .3),
    card: TalkCard(
      ask: '不能出去玩的時候，你會覺得怎麼樣？',
      say: '計畫不能做會失望、會無聊。可以一起想想在家裡可以玩什麼。',
      tip: '無聊沒關係，也是想出新遊戲的時候。',
    ),
  ),
  Story(
    id: 'blamed',
    title: '被誤會',
    line: '積木倒了，大家都說是小雨弄的，可是不是她。',
    place: StoryPlace.school,
    right: [Feeling.wronged, Feeling.sad, Feeling.angry],
    small: [Feeling.sad, Feeling.angry],
    props: [Prop('blocks_fallen', .74, .9, .26)],
    xiaoyu: (.34, .9, .3),
    card: TalkCard(
      ask: '有沒有被誤會的時候？那時候心裡是什麼感覺？',
      say: '被誤會會委屈，想哭又說不出來。可以說「不是我」，也可以請大人幫忙。',
      tip: '相信孩子的感覺，先問「發生什麼事了？」。',
    ),
  ),
  Story(
    id: 'mom_back',
    title: '媽媽回來了',
    line: '門打開，媽媽回來了！',
    place: StoryPlace.home,
    right: [Feeling.calm, Feeling.happy],
    small: [Feeling.happy],
    props: [Prop('door_open', .82, .86, .24)],
    cast: [Cast(CloudKind.grownup, .78, .88, .28, tint: 0xFFFFDDBE, feeling: Feeling.happy, flip: true)],
    xiaoyu: (.36, .9, .3),
    card: TalkCard(
      ask: '爸爸媽媽回家的時候，你心裡覺得怎麼樣？',
      say: '等的人回來了，會好安心、好開心，想跑過去抱抱。',
      tip: '回家時給孩子一個抱抱，說「我回來了，我好想你」。',
    ),
  ),
  Story(
    id: 'sleepy',
    title: '玩了一整天',
    line: '玩了一整天，小雨的眼睛快要閉起來了。',
    place: StoryPlace.night,
    right: [Feeling.tired],
    small: [],
    props: [Prop('bed', .64, .92, .4)],
    xiaoyu: (.28, .9, .28),
    card: TalkCard(
      ask: '你累累的時候，身體有什麼感覺？',
      say: '累了眼睛會重重的、會想躺下來，這時候休息一下就好了。',
      tip: '累了的孩子比較容易生氣，先休息，再講道理。',
    ),
  ),
];

/// A card for each feeling, after the diary (docs/design.md: 每種心情一張).
const feelingCards = <Feeling, TalkCard>{
  Feeling.happy: TalkCard(ask: '今天什麼事讓你最開心？', say: '開心的時候，身體會想跳、想笑，可以跟別人分享。', tip: '也說說你自己今天開心的事。'),
  Feeling.sad: TalkCard(ask: '今天有什麼事讓你難過嗎？', say: '難過的時候可以哭，可以說出來，也可以要一個抱抱。', tip: '不用急著讓孩子不哭，陪著就好。'),
  Feeling.angry: TalkCard(ask: '今天有沒有生氣的時候？是因為什麼？', say: '生氣可以，打人、丟東西不可以。可以深呼吸、搥枕頭、說「我很生氣」。', tip: '等孩子冷靜下來，再一起想下次怎麼做。'),
  Feeling.scared: TalkCard(ask: '有什麼東西讓你害怕嗎？', say: '害怕的時候，可以來找爸爸媽媽，我們會保護你。', tip: '認真聽孩子怕什麼，不笑他。'),
  Feeling.surprised: TalkCard(ask: '今天有沒有讓你嚇一跳的事？', say: '沒想到的事會讓人驚訝，有好的驚訝，也有嚇一跳的驚訝。', tip: '可以一起做出「驚訝的臉」看看。'),
  Feeling.shy: TalkCard(ask: '什麼時候你會覺得害羞？', say: '害羞的時候臉會紅紅的，很多人都會，慢慢來就好。', tip: '不用逼孩子打招呼，可以先揮揮手。'),
  Feeling.nervous: TalkCard(ask: '今天有沒有緊張的事？', say: '緊張的時候心會跳得很快，可以深呼吸，數到四。', tip: '說說你自己緊張時怎麼辦，孩子會學。'),
  Feeling.disappointed: TalkCard(ask: '有沒有本來想要、結果沒有的事？', say: '想要的沒有了會失望，可以說「好可惜」，再想想別的辦法。', tip: '承認「好可惜喔」，比說「沒關係啦」更好。'),
  Feeling.proud: TalkCard(ask: '今天你做到了什麼厲害的事？', say: '做到一件事會得意，覺得「我好厲害」。', tip: '問他怎麼做到的，讓他多說一點。'),
  Feeling.tired: TalkCard(ask: '你累了嗎？身體哪裡覺得累？', say: '累了就要休息，休息完會比較有力氣。', tip: '累的時候早一點睡，明天心情會比較好。'),
  Feeling.bored: TalkCard(ask: '無聊的時候，你都玩什麼？', say: '無聊的時候可以想一個新遊戲，或是看看窗外。', tip: '不用馬上給手機，讓孩子自己想想看。'),
  Feeling.jealous: TalkCard(ask: '有沒有很想要別人的東西的時候？', say: '看到別人有、自己沒有，會嫉妒，這是很正常的感覺。', tip: '說出他的感覺：「你也好想要。」'),
  Feeling.calm: TalkCard(ask: '什麼時候你覺得最安心？', say: '和喜歡的人在一起、抱著小被被，會覺得好安心。', tip: '睡前的抱抱和聊天，是很好的安心時間。'),
  Feeling.wronged: TalkCard(ask: '有沒有覺得「不公平」「被誤會」的時候？', say: '被誤會、覺得不公平，會很委屈，可以說出來，我們會聽。', tip: '先相信孩子的感覺，再一起弄清楚發生什麼事。'),
};
