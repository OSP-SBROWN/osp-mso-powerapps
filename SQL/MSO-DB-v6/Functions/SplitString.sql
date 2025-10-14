CREATE FUNCTION dbo.SplitString (
    @String NVARCHAR(MAX),
    @Delimiter CHAR(1)
)
RETURNS @Result TABLE (Value NVARCHAR(MAX))
AS
BEGIN
    DECLARE @Position INT;
    SET @String = @String + @Delimiter;

    WHILE CHARINDEX(@Delimiter, @String) > 0
    BEGIN
        SET @Position = CHARINDEX(@Delimiter, @String);
        INSERT INTO @Result (Value) 
        VALUES (LTRIM(RTRIM(LEFT(@String, @Position - 1))));
        SET @String = RIGHT(@String, LEN(@String) - @Position);
    END;
    RETURN;
END;

GO

