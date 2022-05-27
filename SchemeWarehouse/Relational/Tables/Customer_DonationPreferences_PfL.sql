CREATE TABLE [Relational].[Customer_DonationPreferences_PfL] (
    [DonationPreferences_PfL_ID] INT         IDENTITY (1, 1) NOT NULL,
    [FanID]                      INT         NOT NULL,
    [PrimaryPANID]               INT         NULL,
    [DonationAmount]             SMALLMONEY  NOT NULL,
    [FailedDonationsCount]       TINYINT     NOT NULL,
    [MaxMonthlyDonation]         SMALLMONEY  NULL,
    [GiftAid]                    BIT         NOT NULL,
    [EmployerMatchingCode]       VARCHAR (8) NULL,
    PRIMARY KEY CLUSTERED ([DonationPreferences_PfL_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_DonPrefs_FanID]
    ON [Relational].[Customer_DonationPreferences_PfL]([FanID] ASC);

