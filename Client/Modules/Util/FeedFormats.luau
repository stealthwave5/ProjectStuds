--[[
	Author(s): Gory
	Module: FeedFormats.luau
--]]

local GuiStyles = shared("GuiStyles") ---@module GuiStyles

export type FeedFormat = {
	Color: Color3?,
	Text: string,
	Time: number?,
}

local FeedFormats: { [string]: FeedFormat } = {
	Locked = {
		Color = GuiStyles.Colors.Green,
		Text = "You locked your base for %s seconds!",
		Time = 7,
	},

	SlotsFull = {
		Color = GuiStyles.Colors.Red,
		Text = "You need more room in your base to buy a country.",
	},

	CantAfford = {
		Color = GuiStyles.Colors.Red,
		Text = "You need %s more to buy this",
	},

	BoughtTool = {
		Color = GuiStyles.Colors.Green,
		Text = "You bought the %s.",
	},

	Rebirthed = {
		Color = GuiStyles.Colors.Green,
		Text = "Successfully rebirthed.",
	},

	StealStarted = {
		Color = GuiStyles.Colors.Red,
		Text = "Someone is stealing your %s",
	},

	StealCompleted = {
		Color = GuiStyles.Colors.Red,
		Text = "%s stole your %s",
	},

	StealLocked = {
		Color = GuiStyles.Colors.Red,
		Text = "This base is locked!",
	},

	StealLimited = {
		Color = GuiStyles.Colors.Red,
		Text = "Can't steal a limited!",
	},

	StealAccountAge = {
		Color = GuiStyles.Colors.Red,
		Text = "Minimum Account Age of %s days required to steal.",
	},

	StealPlayTime = {
		Color = GuiStyles.Colors.Red,
		Text = "Minimum %s time in game required to steal.",
	},

	GiftFailed = {
		Color = GuiStyles.Colors.Red,
		Text = "Gifting failed, try again for no cost.",
	},

	BoughtPass = {
		Color = GuiStyles.Colors.Green,
		Text = "Successfully bought %s",
	},

	BoughtProduct = {
		Color = GuiStyles.Colors.Green,
		Text = "Successfully bought %s",
	},

	GiftedPass = {
		Color = GuiStyles.Colors.Purple,
		Text = "You were gifted %s by %s",
		Time = 10,
	},

	GiftedProduct = {
		Color = GuiStyles.Colors.Purple,
		Text = "You were gifted %s by %s",
		Time = 10,
	},

	CantBuyPass = {
		Color = GuiStyles.Colors.Red,
		Text = "You can't buy this",
	},

	LuckPurchased = {
		Color = GuiStyles.Colors.Green,
		Text = "%s added 15 Minutes of %s",
		Time = 15,
	},

	CashPackBought = {
		Color = GuiStyles.Colors.Green,
		Text = "Added %s of income %s",
	},

	GroupRewardSuccess = {
		Color = GuiStyles.Colors.Green,
		Text = "Success! Enjoy!",
	},

	GroupRewardError = {
		Color = GuiStyles.Colors.Red,
		Text = "Error checking group, try again later.",
	},

	GroupRewardFailed = {
		Color = GuiStyles.Colors.Red,
		Text = "You haven't liked the game AND joined the group.",
	},

	EventStarted = {
		Text = "%s event has started!",
	},

	SpinReward = {
		Color = GuiStyles.Colors.Green,
		Text = "You won %s!",
	},

	FollowersSpinError = {
		Color = GuiStyles.Colors.Red,
		Text = "Please FOLLOW THE DEVELOPERS and try again!",
		Time = 10,
	},

	FollowersSpinAlready = {
		Color = GuiStyles.Colors.Red,
		Text = "You've already redeemed this.",
		Time = 6,
	},

	FollowersSpinClaimed = {
		Color = GuiStyles.Colors.Green,
		Text = "You have claimed a free spin!",
		Time = 10,
	},

	RewardCountryAlt = {
		Color = GuiStyles.Colors.Green,
		Text = "Your base is full. Given value in cash: %s",
	},

	RewardLockTimer = {
		Color = GuiStyles.Colors.Green,
		Text = "Your base is locked for another %s seconds!",
	},

	RewardTimeSkip = {
		Color = GuiStyles.Colors.Gold,
		Text = "Simulated %s of income!",
	},

	ForeverPackResetting = {
		Color = GuiStyles.Colors.Gold,
		Text = "Forever Pack is resetting in %s seconds, please wait.",
	},

	LimitedSoldOut = {
		Color = GuiStyles.Colors.Red,
		Text = "Limited has sold out.",
	},

	MergeInvalid = {
		Color = GuiStyles.Colors.Red,
		Text = "Can't put %s in the Machine",
	},
	MergeFull = {
		Color = GuiStyles.Colors.Red,
		Text = "Machine is full!",
	},
	MergeInserted = {
		Color = GuiStyles.Colors.Green,
		Text = "Added %s to the Machine",
	},
}

return FeedFormats
