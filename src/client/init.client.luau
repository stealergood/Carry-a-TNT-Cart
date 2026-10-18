local Controllers = script:WaitForChild("Controllers")

require(Controllers:WaitForChild("RopeVisualController")).Start()
require(Controllers:WaitForChild("WheelVisualController")).Start()
require(Controllers:WaitForChild("CartPullController")).Start()
require(Controllers:WaitForChild("CartInteractionController")).Start()
