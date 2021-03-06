setup_chart = () ->
  ctx = document.getElementById "burndown-chart"
  window.Burndown = new Chart ctx,
    {
      type: 'line',
      data: {
        labels: ['Monday','Tuesday','Wednesday','Thursday','Friday'],
        datasets: [{
          fill: false,
          showLine: false,
          borderColor: 'rgb(0,240,0,1)',
          borderWidth: 1.5,
          pointStyle: 'star',
          pointRadius: 4.5,
          label: 'points left',
          data: [],
        },
        {
          fill: false,
          borderColor: 'rgb(255,0,0,1)',
          pointStyle: 'circle',
          pointRadius: 4.5,
          lineTension: 0,
          label: 'ideal',
          data: [],
        }],
      },
      options: { scales: { yAxes: [{ ticks: { beginAtZero: true }}]}},
    }

