import { useState } from 'react';

function App() {
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setResponse('');

    try {
      const res = await fetch('/api/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ prompt: prompt }),
      });

      if (res.status === 503) {
        setError('Model is loading, please wait…');
      } else if (!res.ok) {
        const data = await res.json();
        setError(data.detail || 'Error generating response');
      } else {
        const data = await res.json();
        setResponse(data.text);
      }
    } catch (err) {
      setError('Failed to connect to API');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '800px', margin: '50px auto', fontFamily: 'sans-serif' }}>
      <h1>LLM Prompt Interface</h1>
      
      <form onSubmit={handleSubmit}>
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="Enter your prompt here..."
          rows="5"
          style={{
            width: '100%',
            padding: '10px',
            fontSize: '14px',
            fontFamily: 'monospace',
          }}
        />
        <br />
        <button
          type="submit"
          disabled={loading || !prompt.trim()}
          style={{
            marginTop: '10px',
            padding: '10px 20px',
            fontSize: '16px',
            cursor: loading ? 'not-allowed' : 'pointer',
            opacity: loading || !prompt.trim() ? 0.6 : 1,
          }}
        >
          {loading ? 'Generating...' : 'Generate'}
        </button>
      </form>

      {error && (
        <div style={{ marginTop: '20px', padding: '10px', color: 'red', border: '1px solid red' }}>
          {error}
        </div>
      )}

      {response && (
        <div style={{ marginTop: '20px', padding: '10px', backgroundColor: '#f5f5f5', border: '1px solid #ddd' }}>
          <h3>Response:</h3>
          <p>{response}</p>
        </div>
      )}
    </div>
  );
}

export default App;
