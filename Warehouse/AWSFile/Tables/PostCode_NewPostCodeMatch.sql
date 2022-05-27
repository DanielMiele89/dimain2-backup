CREATE TABLE [AWSFile].[PostCode_NewPostCodeMatch] (
    [ConsumerCombinationID] INT          NOT NULL,
    [BrandID]               SMALLINT     NOT NULL,
    [PostCode]              VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_AWSFile_PostCode_NewPostCodeMatch] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

