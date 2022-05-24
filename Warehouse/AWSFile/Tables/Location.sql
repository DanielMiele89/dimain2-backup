CREATE TABLE [AWSFile].[Location] (
    [LocationID] INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]    SMALLINT     NOT NULL,
    [PostCode]   VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_AWSFile_Location] PRIMARY KEY CLUSTERED ([LocationID] ASC)
);

