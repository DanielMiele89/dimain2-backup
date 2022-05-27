CREATE TABLE [Email].[NewsletterTestSchedule] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [PublisherID]     VARCHAR (50) NOT NULL,
    [EmailSendDate]   DATE         NULL,
    [TestDescription] VARCHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

