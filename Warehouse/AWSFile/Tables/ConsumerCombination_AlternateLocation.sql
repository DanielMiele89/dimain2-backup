CREATE TABLE [AWSFile].[ConsumerCombination_AlternateLocation] (
    [ConsumerCombinationID] INT  NOT NULL,
    [AlternateLocationID]   INT  NOT NULL,
    [InsertDate]            DATE CONSTRAINT [DF_AWSFile_ConsumerCombination_AlternateLocation_InsertDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_AWSFile_ConsumerCombination_AlternateLocation] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

