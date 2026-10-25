let chart = null;
let currentTimeframe = '1D';

function initChart() {
  const options = {
    chart: { type: 'area', height: 384, toolbar: { show: false }, fontFamily: 'inherit' },
    colors: ['#2563eb'],
    stroke: { width: 2, curve: 'smooth' },
    series: [{ name: 'Price', data: [] }],
    xaxis: { type: 'datetime' },
    yaxis: { labels: { formatter: val => '$' + parseFloat(val).toFixed(2) } },
    noData: { text: 'Loading market data...' }
  };
  chart = new ApexCharts(document.querySelector("#chart"), options);
  chart.render();
}

async function updateDashboard() {
  const tickerInput = document.getElementById('stock-ticker').value;
  if (!tickerInput) return;

  const status = document.getElementById('status');
  document.getElementById('loading').classList.remove('hidden');

  try {
    const res = await fetch(`/api/stock_data?ticker=${tickerInput}&timeframe=${currentTimeframe}`);
    const json = await res.json();
    status.textContent = '';

    if (json.error) {
      status.textContent = json.error;
      return;
    }

    const dataKey = (currentTimeframe === '1Y') ? "Weekly Time Series" : "Time Series (Daily)";
    const rawSeries = json[dataKey];
    if (!rawSeries) {
      status.textContent = 'Unexpected response from the server.';
      return;
    }

    let formattedData = Object.keys(rawSeries).map(dateStr => ({
      x: new Date(dateStr).getTime(),
      y: parseFloat(rawSeries[dateStr]["4. close"])
    })).sort((a, b) => a.x - b.x);

    if (currentTimeframe === '1D') {
      formattedData = formattedData.slice(-10);
    } else if (currentTimeframe === '1M') {
      formattedData = formattedData.slice(-22);
    } else {
      formattedData = formattedData.slice(-52); // 1Y = last 52 weeks
    }

    chart.updateOptions({
      series: [{ name: 'Closing Price', data: formattedData }]
    });

    if (json.demo) status.textContent = 'Demo data (API limit reached)';
  } catch (e) {
    console.error("Dashboard error:", e);
    status.textContent = 'Could not load data.';
  } finally {
    document.getElementById('loading').classList.add('hidden');
  }
}

document.getElementById('stock-ticker').addEventListener('change', () => updateDashboard());

document.querySelectorAll('.tf-btn').forEach(btn => {
  btn.addEventListener('click', (e) => {
    document.querySelectorAll('.tf-btn').forEach(b => {
      b.classList.remove('text-blue-600', 'bg-blue-50', 'border-blue-600');
      b.classList.add('text-gray-700', 'bg-white', 'border-gray-300');
    });
    e.target.classList.remove('text-gray-700', 'bg-white', 'border-gray-300');
    e.target.classList.add('text-blue-600', 'bg-blue-50', 'border-blue-600');

    currentTimeframe = e.target.getAttribute('data-timeframe');
    updateDashboard();
  });
});

initChart();
updateDashboard();