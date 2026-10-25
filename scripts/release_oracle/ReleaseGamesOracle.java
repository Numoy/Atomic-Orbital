import java.util.ArrayList;
import java.util.List;

public class ReleaseGamesOracle {
  // ORIGINAL_RESOURCE_IDS

  static class MenuActivity { static boolean hardcore_mode; }
  static class Atom { int score; }
  static class AtomController {
    Atom atom = new Atom();
    Atom getAtom() { return atom; }
  }
  static class Settings {
    int highScore, hardcoreHighScore, gamesPlayed, totalPoints;
    int getHighscore() { return highScore; }
    int getHardcoreHighscore() { return hardcoreHighScore; }
    void setHighscore(int score) { highScore = score; }
    void setHardcoreHighscore(int score) { hardcoreHighScore = score; }
    int getGamesPlayed() { return gamesPlayed; }
    void setGamesPlayed() { gamesPlayed++; }
    void totalPoints(int score) { totalPoints += score; }
    int getTotalPoints() { return totalPoints; }
  }

  static class OriginalRules {
    AtomController atomController = new AtomController();
    Settings settings = new Settings();
    ResourceStrings uiThread = new ResourceStrings();
    List<String> events = new ArrayList<>();

    // Capture logical requests where the original calls the Google SDK.
    private void saveScorePlayGames(int score, String leaderboard) {
      events.add("{\"method\":\"submitScore\",\"arguments\":{\"leaderboardId\":\"" +
          leaderboard + "\",\"score\":" + score + "}}");
    }
    private void unlockAchievement(String achievement) {
      events.add("{\"method\":\"unlockAchievement\",\"arguments\":{\"achievementId\":\"" +
          achievement + "\"}}");
    }

    // ORIGINAL_RULE_METHODS
  }

  static String scenario(String label, int score, boolean hardcore, int previousHighScore,
      int previousGames, int previousPoints) {
    OriginalRules rules = new OriginalRules();
    MenuActivity.hardcore_mode = hardcore;
    rules.atomController.atom.score = score;
    rules.settings.highScore = previousHighScore;
    rules.settings.hardcoreHighScore = previousHighScore;
    rules.settings.gamesPlayed = previousGames;
    rules.settings.totalPoints = previousPoints;
    rules.setHighscore();
    return "{\"label\":\"" + label + "\",\"score\":" + score +
        ",\"hardcore\":" + hardcore + ",\"previousHighScore\":" + previousHighScore +
        ",\"gamesPlayedBefore\":" + previousGames + ",\"totalPointsBefore\":" + previousPoints +
        ",\"gamesPlayed\":" + rules.settings.gamesPlayed + ",\"totalPoints\":" + rules.settings.totalPoints +
        ",\"events\":[" + String.join(",", rules.events) + "]}";
  }

  public static void main(String[] args) {
    List<String> scenarios = new ArrayList<>();
    for (boolean hardcore : new boolean[] {false, true}) {
      for (int score : new int[] {0, 19, 20, 34, 35, 49, 50, 51}) {
        scenarios.add(scenario("score_" + score + "_hardcore_" + hardcore, score, hardcore, 0, 0, 0));
      }
      for (int score : new int[] {19, 20, 35, 50}) {
        scenarios.add(scenario("no_new_record_" + score + "_hardcore_" + hardcore, score, hardcore, 50, 0, 0));
      }
    }
    for (int previousGames : new int[] {48, 49, 148, 149, 498, 499}) {
      scenarios.add(scenario("completed_games_" + (previousGames + 1), 0, false, 0, previousGames, 0));
    }
    for (int totalPoints : new int[] {499, 500, 999, 1000, 9999, 10000}) {
      scenarios.add(scenario("total_points_" + totalPoints, 1, false, 10, 0, totalPoints - 1));
    }
    scenarios.add(scenario("all_highest_tiers", 50, true, 0, 499, 9950));
    System.out.println("{\"cases\":[" + String.join(",", scenarios) + "]}");
  }
}
