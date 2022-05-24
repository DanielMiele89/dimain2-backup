CREATE TABLE [RBSMIPortal].[Customer] (
    [FanID]                       INT     NOT NULL,
    [GenderID]                    TINYINT NOT NULL,
    [AgeBandID]                   TINYINT NOT NULL,
    [BankID]                      TINYINT NOT NULL,
    [RainbowID]                   TINYINT NOT NULL,
    [ChannelPreferenceID]         TINYINT NOT NULL,
    [JourneyStageID]              TINYINT NOT NULL,
    [ActivationMethodID]          TINYINT NOT NULL,
    [JourneyStageDetailedID]      TINYINT NOT NULL,
    [FirstSchemeMembershipTypeID] TINYINT NOT NULL,
    [LastSchemeMembershipTypeID]  TINYINT NOT NULL,
    CONSTRAINT [PK_RBSMIPortal_Customer_FanID] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

