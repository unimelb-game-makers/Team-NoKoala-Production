@abstract
class_name Job

var priority: float = 0.0


@abstract
func create_driver(consumer: JobConsumer) -> JobDriver
