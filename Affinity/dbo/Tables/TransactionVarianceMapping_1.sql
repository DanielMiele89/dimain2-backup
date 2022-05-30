CREATE TABLE [dbo].[TransactionVarianceMapping] (
    [RangeBottom] DECIMAL (10, 2) NULL,
    [RangeTop]    DECIMAL (10, 2) NULL,
    [Variance]    DECIMAL (10, 2) NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Holds the ranges and variances to be applied for transaction values', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TransactionVarianceMapping';

