CREATE TABLE [AWSFile].[ComboPostCode] (
    [ConsumerCombinationID] INT          NOT NULL,
    [PostCode]              VARCHAR (50) NOT NULL,
    [LocationID]            INT          NOT NULL,
    CONSTRAINT [PK_AWSFile_ComboPostCode] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

