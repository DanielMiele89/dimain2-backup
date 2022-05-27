CREATE TABLE [Staging].[LocationAdditional] (
    [LocationID]            INT          IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT          NOT NULL,
    [LocationAddress]       VARCHAR (50) NOT NULL,
    [IsNonLocational]       BIT          NOT NULL,
    CONSTRAINT [PK_Staging_LocationAdditional] PRIMARY KEY CLUSTERED ([LocationID] ASC)
);

