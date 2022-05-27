CREATE TABLE [Relational].[DonationFiles_PfL] (
    [DonationFiles_PfL_ID] INT      NOT NULL,
    [CreateDate]           DATETIME NULL,
    [Status]               INT      NULL,
    PRIMARY KEY CLUSTERED ([DonationFiles_PfL_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_DonFiles_CreateDate]
    ON [Relational].[DonationFiles_PfL]([CreateDate] ASC);

