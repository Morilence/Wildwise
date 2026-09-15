package.path = "./scripts/?.lua;./?.lua;" .. package.path
require("tests/core_spec")
require("tests/config_spec")
require("tests/services_spec")
require("tests/regression_spec")
require("tests/workshop_spec")
require("tests/capabilities_spec")
require("tests/optimization_spec")
local H = require("tests/harness")
io.write(string.format("\n%d passed, %d failed\n", H.passed, H.failed))
if H.failed > 0 then
    os.exit(1)
end
