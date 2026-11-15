import '../core/calm.dart';
import '../core/feelings.dart';

/// Everything the app says, in Traditional Chinese (Taiwan).
abstract final class Strings {
  static const appName = '心情小屋';

  // The house.
  static const hello = '你好！今天的心情怎麼樣呢？';
  static String helloAgain(Feeling f) => '今天你是${f.zh}的！記得說給爸爸媽媽聽喔。';
  static String today(Feeling f) => '今天：${f.zh}';
  static const faces = '認表情';
  static const story = '小故事';
  static const calm = '冷靜小屋';
  static const help = '怎麼辦';
  static const diary = '心情日記';
  static const parent = '家長';
  static const again = '再聽一次';
  static const back = '回去';
  static const home = '回小屋';
  static const locked = '完整版才有喔，請爸爸媽媽看看。';
  static String mianmianSays(Feeling f) => '我現在覺得${f.zh}。';

  // 認表情.
  static const facesAsk = '棉棉現在是什麼心情？';
  static const facesTap = '點一個，聽聽看';
  static String facesRight(Feeling f) => '對，我在${f.zh}！';
  static String facesWrong(Feeling f, bool brows) => '我不是${f.zh}喔，再看看我的${brows ? '眉毛' : '嘴巴'}。';
  static const howKnow = '你怎麼知道的？';
  static const nextOne = '下一個';

  // 小故事.
  static const storyAsk = '小雨現在是什麼心情？';
  static String storyRight(Feeling f, List<Feeling> others) => '對，小雨很${f.zh}。${others.isEmpty ? '' : '也可能會${others.map((o) => o.zh).join('、')}喔。'}';
  static String storyWrong(Feeling f) => '小雨不是${f.zh}喔，再看看她的臉。';
  static const ifYou = '如果是你，你會怎麼樣？';
  static const alsoRight = '也可以';
  static const whatToDo = '怎麼辦？';
  static const talk = '家長一起說';
  static const nextStory = '下一個故事';
  static const goCalm = '一起去冷靜小屋';

  // 怎麼辦.
  static String helpAsk(Feeling f, bool pleasant) => pleasant ? '小雨好${f.zh}！你可以怎麼做呢？' : '小雨好${f.zh}。你可以怎麼做呢？';
  static const helpAllGood = '三個都是好方法，點一個試試看';
  static const shareNote = '分享和輪流，留給真的朋友一起練';
  static String selfAsk(Feeling f) => '如果你很${f.zh}，可以怎麼做？';
  static const selfNote = '點一個，就去冷靜小屋做做看';

  // 冷靜小屋.
  static const calmPick = '選一個讓自己冷靜的方法';
  static const calmDone = '我冷靜下來了，謝謝你陪我！';
  static const calmAgain = '再做一個';
  static const calmBest = '哪一個最有用？';
  static String calmBestSaid(CalmWay w) => '${w.zh}最有用！我記下來了。';
  static const holdIn = '按住\n吸氣';
  static const breatheIn = '慢慢吸氣～';
  static const breatheOut = '慢慢吐氣～';
  static const holdLonger = '再慢慢吸一次，按久一點';
  static const inhale = '吸氣';
  static const exhale = '吐氣';
  static String breaths(int n) => '第 $n 次';
  static const numbers = ['一', '二', '三', '四'];
  static const countDone = '一、二、三、四，我冷靜下來了。';
  static const teddyHere = '小熊來了，抱一抱～';
  static const pillowHit = '用力點枕頭！';
  static const pillowShake = '也可以搖一搖手機';
  static const drink = '咕嚕咕嚕，好舒服。';
  static const callAdult = '請大人來';
  static const adultHere = '「我在這裡。」大人來了。';
  static const goFindAdult = '現在換你去找大人。';

  // 心情日記.
  static const diaryAsk = '今天，你的心情是？';
  static String diaryPicked(Feeling f) => '今天你是${f.zh}的！去說給爸爸媽媽聽。';
  static const tellParents = '說給爸爸媽媽聽';
  static String toParents(Feeling f) => '爸爸媽媽，我今天覺得${f.zh}。';
  static const thisWeek = '這一個星期';

  // 家長一起說.
  static const forGrownUps = '這一頁給大人看';
  static const ask = '問問孩子';
  static const say = '可以一起說';
  static const tip = '小提醒';
  static const readOut = '念出來';
  static const nextCard = '下一個問題';

  // Resting.
  static const restTitle = '該休息了';
  static const restLine = '換你去做了！\n去跟爸爸媽媽說說\n你今天的心情。';

  // Parent gate (as in the sibling apps).
  static const callParent = '請爸爸媽媽來幫忙喔！';
  static const parentGateTitle = '家長確認';
  static String gateQuestion(String a, String b) => '$a 加 $b 等於多少？';
  static const gateRules = '答錯三次要等一分鐘。';
  static const wrongAnswer = '不對喔，換一題。';
  static String gateWait(int s) => '請等 $s 秒再試';
  static const backspace = '刪掉';
  static const cancel = '取消';

  // Parent mode.
  static const parentTitle = '家長模式';
  static const age = '年齡（難度）';
  static String levelLine(Level l) => '${l.zh}（${l.ages}）';
  static const ageNote = '小小：開心、難過、生氣、害怕四種心情，一次兩個選項，冷靜小屋有吹氣球、抱抱、找大人。大：十四種心情，四個選項，小故事會多問「如果是你呢？」，冷靜小屋六個方法都有。';
  static const playTime = '每次可以玩多久';
  static String minutes(int m) => '$m 分鐘';
  static const playTimeNote = '時間到了棉棉打哈欠、小屋的燈亮起來，APP 說「換你去做了！」。要家長解開，或等一個小時，才能再玩。冷靜小屋不受時間限制。';
  static const playOn = '讓小朋友再玩一次（重新計時）';
  static const resting = '現在是休息時間。';
  static const openCalm = '打開冷靜小屋（不限時間）';
  static const openCalmNote = '小朋友真的在生氣、難過的時候，直接帶他到冷靜小屋。';
  static const talkCards = '家長一起說';
  static const talkCardsSwitch = '每個故事和日記後，出現給大人的問題卡';
  static const shake = '搥枕頭時，搖手機也可以';
  static const feelingsTitle = '要哪些心情';
  static const feelingsNote = '可以先關掉一些（例如害怕），之後再打開；開心和安心一定有。';
  static const diaryTitle = '心情日記';
  static const diaryNone = '這個星期還沒有寫日記。';
  static String mostFelt(Feeling f) => '這個月最常選的：${f.zh}';
  static String mostCalm(CalmWay w) => '最常用的冷靜方法：${w.zh}';
  static String dayLine(String weekday, Feeling? f, Map<CalmWay, int> calm, CalmWay? best) {
    final parts = <String>[f == null ? '沒有寫' : f.zh];
    if (calm.isNotEmpty) parts.add('冷靜小屋：${calm.keys.map((w) => w.zh).join('、')}');
    if (best != null) parts.add('最有用：${best.zh}');
    return '星期$weekday：${parts.join('，')}';
  }

  static const sound = '聲音';
  static const music = '背景音樂';
  static const effects = '音效';
  static const voice = '念出題目和心情的名字';
  static const english = '心情的名字，國語說完再說英文（happy）';
  static const together = '生活中一起做';
  static const tips = [
    '每天睡前問一句：「今天什麼時候最開心？什麼時候有一點難過？」',
    '說出孩子的心情：「你很生氣，因為積木倒了。」先說出來，再一起想辦法。',
    '大人也說自己的心情：「媽媽今天有點累。」孩子會學著說。',
    '孩子在生氣時，先陪他冷靜（深呼吸、抱抱），冷靜了再講道理。',
    '分享和輪流，請和真的朋友、兄弟姊妹一起練。',
  ];
  static const fullVersion = '完整版';
  static const fullNote = '免費版有認表情（四種心情）、冷靜小屋的吹氣球和找大人、心情日記；完整版有十四種心情、全部小故事和怎麼辦、六個冷靜方法和家長一起說的問題卡。（測試版先全部打開。）';
  static const fullSwitch = '打開完整版（測試用）';
  static const about = '關於';
  static const privacy = '不連網、不定位、沒有廣告、沒有帳號；心情日記只存在這支手機裡，不會傳給任何人。';
  static String version(String v) => '版本 $v';

}
