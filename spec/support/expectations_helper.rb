module ExpectationsHelper
  def is_anticipated
    expect { subject }
  end

  def is_anticipated_with_error
    expect do
      subject
    rescue StandardError
      yield if block_given?
    end
  end

  def will
    yield if block_given?
    subject
  end

  def does
    subject
    yield if block_given?
  end

  def will_with_error
    yield if block_given?
    subject
  rescue StandardError
  end
end
