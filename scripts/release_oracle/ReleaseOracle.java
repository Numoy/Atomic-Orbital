import android.content.Context;
import android.util.Size;
import de.numpy.orbital.orbital4.constants.Constants;
import de.numpy.orbital.orbital4.gameobjects.player.Player;
import de.numpy.orbital.orbital4.gameobjects.player.PlayerController;
import de.numpy.orbital.orbital4.gameobjects.photon.*;
import de.numpy.orbital.orbital4.hitpoints.HitpointsController;
import de.numpy.orbital.orbital4.mainmenu.MenuActivity;
import de.numpy.orbital.orbital4.orbit.OrbitController;
import de.numpy.orbital.orbital4.userinput.UserInput;
import java.lang.reflect.Method;

public class ReleaseOracle {
  private static boolean sample(int tick) {
    return tick < 6 || tick == 17 || tick == 18 || tick == 19 || tick == 35 ||
        tick == 36 || tick == 44 || tick == 45 || tick == 59 || tick == 60 ||
        tick == 61 || tick == 69 || tick == 70 || tick == 79 || tick == 80 ||
        tick == 89 || tick == 90 || tick == 94 || tick == 95 || tick == 100 ||
        tick == 101 || tick == 119;
  }

  private static String player(Player player, int tick) {
    return "{\"tick\":" + tick + ",\"angle\":" + player.pos +
        ",\"radius\":" + player.radius + ",\"radialVelocity\":" + player.speedRadius +
        ",\"x\":" + player.posX + ",\"y\":" + player.posY +
        ",\"size\":" + player.objectSize + ",\"direction\":" + player.direction + "}";
  }

  private static String playerTrace(Size size) {
    PlayerController controller = new PlayerController(size);
    UserInput input = new UserInput();
    StringBuilder result = new StringBuilder("{\"width\":" + size.getWidth() +
        ",\"height\":" + size.getHeight() + ",\"initial\":" + player(controller.player, -1) +
        ",\"samples\":[");
    boolean first = true;
    for (int tick = 0; tick < 120; tick++) {
      input.touchDown = tick < 18 || (tick >= 36 && tick < 60) || tick >= 90;
      if (tick == 45 || tick == 80) controller.changeDirection();
      if (tick == 70) controller.shrink();
      if (tick == 95) controller.updateSpeed(3);
      controller.update(input);
      if (sample(tick)) {
        if (!first) result.append(',');
        first = false;
        result.append(player(controller.player, tick));
      }
    }
    assert controller.player.radius >= controller.player.minRadius;
    assert controller.player.radius <= controller.player.maxRadius;
    return result.append("]}").toString();
  }

  private static String photonTrace(Size size, TrajectoryType type, int direction) throws Exception {
    PhotonController controller = new PhotonController(size);
    PhotonModel model = new PhotonModel();
    model.polarPhi = 358.0f;
    model.polarRadius = size.getWidth() * Constants.ATOM_SIZE_FAC;
    model.polarRadiusVel = size.getWidth() * type.RADIAL_VEL_FAC;
    model.polarPhiVel = Constants.PHOTON_PHI_VEL;
    model.trajectoryType = type;
    model.direction = direction;
    Method update = PhotonController.class.getDeclaredMethod("updatePhoton", PhotonModel.class);
    update.setAccessible(true);
    StringBuilder result = new StringBuilder("{\"width\":" + size.getWidth() +
        ",\"height\":" + size.getHeight() + ",\"type\":\"" + type +
        "\",\"direction\":" + direction + ",\"samples\":[");
    boolean first = true;
    for (int tick = 0; tick < 120; tick++) {
      boolean deleted = (Boolean) update.invoke(controller, model);
      assert !deleted;
      if (sample(tick)) {
        if (!first) result.append(',');
        first = false;
        result.append("{\"tick\":" + tick + ",\"angle\":" + model.polarPhi +
            ",\"radius\":" + model.polarRadius + ",\"x\":" + model.posX +
            ",\"y\":" + model.posY + "}");
      }
    }
    return result.append("]}").toString();
  }

  private static String orbitTrace(Size size) {
    OrbitController controller = new OrbitController(size);
    StringBuilder result = new StringBuilder("{\"width\":" + size.getWidth() + ",\"samples\":[");
    for (int tick = 0; tick < 180; tick++) {
      if (tick == 0) controller.addOrbit(5);
      if (tick == 60) controller.addOrbit(10);
      if (tick == 120) controller.addOrbit(20);
      controller.update(0);
      if (tick % 60 == 0 || tick % 60 == 58 || tick % 60 == 59) {
        if (tick != 0) result.append(',');
        result.append("{\"tick\":" + tick + ",\"radii\":[");
        for (int index = 0; index < controller.getOrbitCount(); index++) {
          if (index > 0) result.append(',');
          result.append(controller.getOrbitRadius(index));
        }
        result.append("]}");
      }
    }
    assert controller.getOrbitCount() == 5;
    return result.append("]}").toString();
  }

  private static String healthTrace(boolean hardcore) {
    MenuActivity.hardcore_mode = hardcore;
    HitpointsController controller = new HitpointsController(new Size(1080, 1920), new Context());
    StringBuilder result = new StringBuilder("{\"hardcore\":" + hardcore + ",\"samples\":[");
    boolean first = true;
    for (int tick = 0; tick < 120; tick++) {
      controller.update();
      if (tick == 0 || tick == 30 || tick == 90) controller.photonHit();
      if (sample(tick) || tick == 30) {
        if (!first) result.append(',');
        first = false;
        result.append("{\"tick\":" + tick + ",\"health\":" + controller.getHealth() + "}");
      }
    }
    return result.append("]}").toString();
  }

  private static String waveTrace() {
    PhotonController controller = new PhotonController(new Size(1080, 1920));
    StringBuilder result = new StringBuilder("[");
    boolean first = true;
    for (int tick = 0; tick <= 202; tick++) {
      controller.update(tick == 0 ? 0 : 10);
      if (tick < 3 || tick == 99 || tick == 100 || tick == 101 || tick == 102 || tick == 201 || tick == 202) {
        int growing = 0;
        for (PhotonModel photon : controller.photons) if (photon.growing) growing++;
        if (!first) result.append(',');
        first = false;
        result.append("{\"tick\":" + tick + ",\"count\":" + controller.photons.size() +
            ",\"growing\":" + growing + ",\"firstRadius\":" + controller.photons.get(0).radius + "}");
      }
    }
    assert controller.photons.size() == 7;
    return result.append(']').toString();
  }

  public static void main(String[] args) throws Exception {
    Size[] sizes = {new Size(360, 640), new Size(1080, 1920), new Size(1440, 2560)};
    StringBuilder json = new StringBuilder("{\"players\":[");
    for (int index = 0; index < sizes.length; index++) {
      if (index > 0) json.append(',');
      json.append(playerTrace(sizes[index]));
    }
    json.append("],\"photons\":[");
    boolean first = true;
    for (Size size : sizes) {
      for (TrajectoryType type : TrajectoryType.values()) {
        for (int direction : new int[] {-1, 1}) {
          if (!first) json.append(',');
          first = false;
          json.append(photonTrace(size, type, direction));
        }
      }
    }
    json.append("],\"orbits\":[");
    for (int index = 0; index < sizes.length; index++) {
      if (index > 0) json.append(',');
      json.append(orbitTrace(sizes[index]));
    }
    json.append("],\"health\":[").append(healthTrace(false)).append(',')
        .append(healthTrace(true)).append("],\"waves\":").append(waveTrace()).append('}');
    System.out.println(json);
  }
}
