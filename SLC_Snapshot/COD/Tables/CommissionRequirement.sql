CREATE TABLE [COD].[CommissionRequirement] (
    [ID]               INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CommissionRuleID] INT            NOT NULL,
    [key_name]         NVARCHAR (64)  NOT NULL,
    [key_value]        NVARCHAR (256) NOT NULL,
    CONSTRAINT [PK__Commissi__3214EC27AEEBAE0D] PRIMARY KEY CLUSTERED ([ID] ASC)
);

