CREATE TABLE [COD].[TargetSegmentCriteria] (
    [ID]        INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [OfferID]   INT            NOT NULL,
    [key_name]  NVARCHAR (64)  NOT NULL,
    [key_value] NVARCHAR (256) NOT NULL,
    CONSTRAINT [PK__TargetSe__3214EC27BE92D2AD] PRIMARY KEY CLUSTERED ([ID] ASC)
);

