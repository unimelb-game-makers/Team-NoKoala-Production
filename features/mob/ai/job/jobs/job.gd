@abstract
class_name Job

var priority: float = 0.0

## Exclusive access to a job's targets (items, cells) is handled by
## [ReservationManager], keyed by the owning [JobConsumer] and taken when the
## job is selected. Jobs themselves are transient and hold no reservation state.

@abstract
func create_driver(consumer: JobConsumer) -> JobDriver
