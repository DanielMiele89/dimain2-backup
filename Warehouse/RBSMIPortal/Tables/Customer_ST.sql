CREATE TABLE [RBSMIPortal].[Customer_ST] (
    [FanID]               INT     NOT NULL,
    [GenderID]            TINYINT NOT NULL,
    [AgeBandID]           TINYINT NULL,
    [BankID]              TINYINT NULL,
    [RainbowID]           TINYINT NULL,
    [ChannelPreferenceID] TINYINT NOT NULL,
    [ActivationMethodID]  TINYINT NOT NULL,
    CONSTRAINT [PK_RBSMIPortal_Customer_ST] PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IXNCL_RBSMIPortal_Customer_ST]
    ON [RBSMIPortal].[Customer_ST]([GenderID] ASC, [AgeBandID] ASC, [BankID] ASC, [RainbowID] ASC, [ChannelPreferenceID] ASC, [ActivationMethodID] ASC);

