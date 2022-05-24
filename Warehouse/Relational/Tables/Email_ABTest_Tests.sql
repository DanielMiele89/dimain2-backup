CREATE TABLE [Relational].[Email_ABTest_Tests] (
    [TestID]           INT           IDENTITY (1, 1) NOT NULL,
    [CampaignID]       INT           NOT NULL,
    [TestGroupID]      TINYINT       NOT NULL,
    [Test_Description] VARCHAR (100) NULL,
    CONSTRAINT [pk_TestID] PRIMARY KEY CLUSTERED ([TestID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CampaignID]
    ON [Relational].[Email_ABTest_Tests]([CampaignID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_TestGroupID]
    ON [Relational].[Email_ABTest_Tests]([TestGroupID] ASC);

