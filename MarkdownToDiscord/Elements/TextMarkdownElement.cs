namespace MarkdownToDiscord.Elements;

public class TextMarkdownElement : IMarkdownElement
{
    public readonly string Text;
    
    public TextMarkdownElement(string text)
    {
        this.Text = text;
    }
}