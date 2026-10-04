// Hour-logger maths for finishing hourly jobs: half-hour steps, half an hour minimum.

const double _step = 0.5;

/// Time since [start] at [now], rounded to the nearest half hour.
double loggedHoursSince(DateTime start, DateTime now) {
  final hours = now.difference(start).inMinutes / 60;
  final rounded = (hours / _step).round() * _step;
  return rounded < _step ? _step : rounded;
}

double addHalfHour(double hours) => hours + _step;

double removeHalfHour(double hours) =>
    canRemoveHalfHour(hours) ? hours - _step : hours;

bool canRemoveHalfHour(double hours) => hours - _step >= _step;

int hourlyTotalCop(double hours, int rateCop) => (hours * rateCop).round();
