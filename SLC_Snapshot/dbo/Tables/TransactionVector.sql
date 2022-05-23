CREATE TABLE [dbo].[TransactionVector] (
    [ID]           TINYINT       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name]         NVARCHAR (50) NOT NULL,
    [Type]         NVARCHAR (50) NULL,
    [Abbreviation] NVARCHAR (12) NULL,
    [FeedConsumer] BIT           NOT NULL,
    [status]       TINYINT       NULL,
    CONSTRAINT [PK_TransactionVector] PRIMARY KEY CLUSTERED ([ID] ASC)
);

