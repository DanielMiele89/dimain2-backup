CREATE TABLE [Relational].[Email_ABTest_Members] (
    [MemberID]    INT     IDENTITY (1, 1) NOT NULL,
    [CampaignID]  INT     NULL,
    [FanID]       INT     NULL,
    [TestGroupID] TINYINT NULL,
    PRIMARY KEY CLUSTERED ([MemberID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CampaignID]
    ON [Relational].[Email_ABTest_Members]([CampaignID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[Email_ABTest_Members]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_TestGroupID]
    ON [Relational].[Email_ABTest_Members]([TestGroupID] ASC);

