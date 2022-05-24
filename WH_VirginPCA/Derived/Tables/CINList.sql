CREATE TABLE [Derived].[CINList] (
    [CINID] INT          IDENTITY (1, 1) NOT NULL,
    [CIN]   VARCHAR (64) NULL,
    CONSTRAINT [PK_CINList] PRIMARY KEY CLUSTERED ([CINID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [Derived].[CINList]([CIN] ASC)
    INCLUDE([CINID]);


GO
GRANT SELECT
    ON OBJECT::[Derived].[CINList] TO [visa_etl_user]
    AS [New_DataOps];

