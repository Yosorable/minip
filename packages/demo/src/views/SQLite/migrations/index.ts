import mig01 from "./migration01";
import mig02 from "./migration02";
import mig03 from "./migration03";

const migrations = {
  [mig01.name]: {
    up: mig01.up,
    down: mig01.down,
  },
  [mig02.name]: {
    up: mig02.up,
    down: mig02.down,
  },
  [mig03.name]: {
    up: mig03.up,
    down: mig03.down,
  },
};

export default migrations;
